import QtQuick
import Quickshell
import qs.common
import qs.components
import qs.services
import qs.modules.dashboard

// Center island, after Clavis's Keystone: a rolling clock that grows sideways to
// carry the current track, and expands into the full media card on hover. Each
// digit is a 0-9 strip that springs to its place. Click the clock for the date and
// right-click it for the calendar; click the track to play/pause, scroll to change song.
Rectangle {
    id: root

    required property QtObject bar

    property bool showDate: false

    // The card follows the pointer across both the island and the card itself, so
    // crossing the gap between them doesn't close it
    readonly property bool pointerOnTrack: mediaMouse.containsMouse || card.hovered
    onPointerOnTrackChanged: pointerOnTrack ? expand.restart() : collapse.restart()

    // Reveal amounts, 0..1. Widths are derived from these, so the pill's own width
    // is never a second animation chasing the first one.
    property real mediaProgress: Media.hasMedia ? 1 : 0
    property real dateProgress: showDate ? 1 : 0
    // The OSD takes the track's place rather than sitting beside it. One number drives
    // both halves of the swap, so the island interpolates straight from one width to
    // the other instead of bulging while two animations cross.
    property real osdProgress: Osd.active ? 1 : 0

    readonly property bool osdMuted: (Osd.kind === "volume" && Audio.muted) || (Osd.kind === "mic" && Audio.micMuted)
    readonly property real osdValue: {
        if (Osd.kind === "mic")
            return Audio.micMuted ? 0 : Audio.micVolume;
        if (Osd.kind === "brightness")
            return Brightness.brightness;
        return Audio.muted ? 0 : Audio.volume;
    }
    readonly property string osdIcon: {
        if (Osd.kind === "mic")
            return Audio.micMuted ? Icons.micMuted : Icons.mic;
        if (Osd.kind === "brightness")
            return Icons.pick(Icons.brightness, Brightness.brightness);
        return Audio.muted ? Icons.volumeMuted : Icons.pick(Icons.volume, Audio.volume);
    }

    readonly property int padding: 14
    readonly property int gap: 12
    readonly property int digitSize: 22
    readonly property real digitHeight: 27
    // Hours carry the text color, minutes the wallpaper accent
    readonly property color hourColor: Theme.surfaceText
    readonly property color minuteColor: Theme.primary

    // 12-hour drops the leading zero rather than showing "09", which is what a clock
    // face does; the rolling digit strip just gets a blank to roll to
    readonly property int hour12: clock.hours % 12 === 0 ? 12 : clock.hours % 12
    readonly property int shownHours: Settings.data.twelveHour ? hour12 : clock.hours
    readonly property int h0: Math.floor(shownHours / 10)
    readonly property int h1: shownHours % 10
    readonly property int m0: Math.floor(clock.minutes / 10)
    readonly property int m1: clock.minutes % 10

    implicitWidth: content.implicitWidth + padding * 2
    implicitHeight: Appearance.islandHeight
    radius: height / 2
    color: Theme.glass
    border.width: 1
    border.color: Theme.glassEdge

    // Springy on the way out, calm on the way back
    Behavior on mediaProgress {
        Anim {
            duration: Media.hasMedia ? Appearance.expandDuration : Appearance.shrinkDuration
            easing.bezierCurve: Media.hasMedia ? Appearance.curveExpand : Appearance.curveShrink
        }
    }

    Behavior on dateProgress {
        Anim {
            duration: Appearance.animNormal
            easing.bezierCurve: Appearance.curveEmphasized
        }
    }

    Behavior on osdProgress {
        Anim {
            duration: Osd.active ? Appearance.expandDuration : Appearance.shrinkDuration
            easing.bezierCurve: Osd.active ? Appearance.curveExpand : Appearance.curveShrink
        }
    }

    // Ticks once a minute, not once a second
    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Row {
        id: content

        anchors.centerIn: parent
        spacing: 0

        // Volume or brightness, for a moment after it moves
        Item {
            id: osdChip

            readonly property real fullWidth: osdRow.implicitWidth + root.gap

            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(fullWidth * root.osdProgress)
            height: root.digitHeight
            visible: width > 0
            opacity: root.osdProgress
            clip: true

            Row {
                id: osdRow

                anchors.verticalCenter: parent.verticalCenter
                spacing: Appearance.spacingSmall + 4

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.osdIcon
                    size: 18
                    color: root.osdMuted ? Theme.critical : Theme.primary
                }

                WavyProgress {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 110
                    // The same dial as the media card, held straight: a wave here would
                    // read as sound rather than as a level
                    wavy: false
                    lineWidth: 5
                    value: root.osdValue
                    color: root.osdMuted ? Theme.critical : Theme.primary
                }

                StyledText {
                    id: osdPercent

                    anchors.verticalCenter: parent.verticalCenter
                    // Right-aligned in a box the width of "100%": the font is monospaced,
                    // so holding a key no longer shifts the clock as the reading passes
                    // 10 and 100
                    width: percentMetrics.width
                    horizontalAlignment: Text.AlignRight
                    text: `${Math.round(root.osdValue * 100)}%`
                    color: root.osdMuted ? Theme.critical : Theme.surfaceText
                    font.pixelSize: Appearance.fontSize

                    TextMetrics {
                        id: percentMetrics

                        font: osdPercent.font
                        text: "100%"
                    }
                }
            }
        }

        // Now playing: art, title, and the gap before the clock
        Item {
            id: mediaChip

            // Animated here rather than on the pill, so the pill's width always
            // matches its contents exactly instead of trailing them
            property real fullWidth: mediaRow.implicitWidth + root.gap

            anchors.verticalCenter: parent.verticalCenter
            // Yields the slot to the OSD. Both terms come off the one animated number,
            // so the island's width slides between the two contents without a bump.
            width: Math.round(fullWidth * root.mediaProgress * (1 - root.osdProgress))
            height: root.digitHeight
            visible: width > 0
            opacity: root.mediaProgress * (1 - root.osdProgress)
            clip: true

            // Lets the pill glide when a new track has a longer name
            Behavior on fullWidth {
                Anim {
                    duration: Appearance.animNormal
                }
            }

            Row {
                id: mediaRow

                anchors.verticalCenter: parent.verticalCenter
                spacing: Appearance.spacingSmall + 2

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Media.playing ? Icons.pause : Icons.play
                    size: 18
                    color: Theme.primary
                }

                // The old title slides up and out, the new one rises into its place,
                // so a track change is the only thing that ever animates here
                Item {
                    id: titleClip

                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: titleText.width
                    implicitHeight: 21
                    clip: true

                    StyledText {
                        id: titleText

                        // Held rather than bound: the outgoing title has to stay on
                        // screen while it leaves
                        property string pending: Media.title

                        width: Math.min(implicitWidth, 260)
                        height: titleClip.height
                        color: Media.playing ? Theme.surfaceText : Qt.alpha(Theme.surfaceText, 0.55)
                        font.pixelSize: Appearance.fontSize + 2
                        font.italic: !Media.playing
                        onPendingChanged: flip.restart()
                        Component.onCompleted: text = pending
                    }

                    SequentialAnimation {
                        id: flip

                        ParallelAnimation {
                            Anim {
                                target: titleText
                                property: "y"
                                to: -titleClip.height
                                duration: Appearance.animFast
                            }

                            Anim {
                                target: titleText
                                property: "opacity"
                                to: 0
                                duration: Appearance.animFast
                            }
                        }

                        ScriptAction {
                            script: {
                                titleText.text = titleText.pending;
                                titleText.y = titleClip.height;
                            }
                        }

                        ParallelAnimation {
                            Anim {
                                target: titleText
                                property: "y"
                                to: 0
                                duration: Appearance.animNormal
                                easing.bezierCurve: Appearance.curveEmphasized
                            }

                            Anim {
                                target: titleText
                                property: "opacity"
                                to: 1
                                duration: Appearance.animNormal
                            }
                        }
                    }
                }
            }

            MouseArea {
                id: mediaMouse

                anchors.fill: mediaRow
                // Off while the OSD has the slot: the track is still under the pointer,
                // but it is not what the island is showing
                enabled: root.osdProgress < 0.5
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                // Middle click steps to the next player, for when several are loaded
                onClicked: mouse => mouse.button === Qt.MiddleButton ? Media.cyclePlayer() : Media.togglePlaying()
                onWheel: event => event.angleDelta.y > 0 ? Media.previous() : Media.next()
            }
        }

        // Date, revealed by clicking the clock
        Item {
            id: dateChip

            readonly property real fullWidth: dateRow.implicitWidth + root.gap

            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(fullWidth * root.dateProgress)
            height: root.digitHeight
            visible: width > 0
            opacity: root.dateProgress
            clip: true

            Row {
                id: dateRow

                anchors.verticalCenter: parent.verticalCenter
                spacing: root.gap

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDate(clock.date, "ddd MMM dd")
                    color: Theme.primary
                    font.pixelSize: Appearance.fontSize
                    font.weight: Font.Bold
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: 2
                    implicitHeight: 14
                    radius: width / 2
                    color: Qt.alpha(Theme.surfaceText, 0.25)
                }
            }
        }

        // The clock and its click target live in a plain Item: a Row lets its
        // children centre vertically, but not fill it
        Item {
            id: clockBox

            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: clockRow.implicitWidth
            implicitHeight: root.digitHeight

            Row {
                id: clockRow

                anchors.centerIn: parent
                spacing: 6

                Row {
                    spacing: 0

                    // A 24-hour clock spends half the day with a leading zero. Holding
                    // it back keeps the hour reading as one number instead of two.
                    RollingDigit {
                        value: root.h0
                        tint: root.h0 === 0 ? Qt.alpha(root.hourColor, 0.32) : root.hourColor
                    }

                    RollingDigit {
                        value: root.h1
                        tint: root.hourColor
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Repeater {
                        model: 2

                        Rectangle {
                            implicitWidth: 3.5
                            implicitHeight: 3.5
                            radius: width / 2
                            color: Qt.alpha(Theme.surfaceText, 0.45)
                        }
                    }
                }

                Row {
                    spacing: 0

                    RollingDigit {
                        value: root.m0
                        tint: root.minuteColor
                    }

                    RollingDigit {
                        value: root.m1
                        tint: root.minuteColor
                    }
                }
            }

            MouseArea {
                id: clockMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton)
                        calendar.toggle();
                    else
                        root.showDate = !root.showDate;
                }
            }
        }
    }

    Tooltip {
        target: clockRow
        text: Qt.formatDate(clock.date, "dddd, MMMM d, yyyy")
        show: clockMouse.containsMouse && !root.showDate && !calendar.open
    }

    Dashboard {
        id: calendar

        target: clockBox
        bar: root.bar
        today: clock.date
    }

    // Hovering the track expands the island into the full card: art, progress and
    // controls. It takes no focus grab, so it never swallows a click meant elsewhere.
    Popout {
        id: card

        target: mediaChip
        bar: root.bar
        contentWidth: 520
        grabsFocus: false

        Loader {
            active: card.open

            sourceComponent: Component {
                MediaCard {
                    active: card.open
                }
            }
        }
    }

    Timer {
        id: expand

        interval: 320
        onTriggered: card.open = root.pointerOnTrack && Media.hasMedia
    }

    Timer {
        id: collapse

        interval: 220
        onTriggered: if (!root.pointerOnTrack)
            card.open = false
    }

    Connections {
        target: Media

        function onHasMediaChanged(): void {
            if (!Media.hasMedia)
                card.open = false;
        }
    }

    // One digit: a 0-9 strip that slides so only the wanted number shows.
    // Cheaper than ten items, and the spring gives it the flip-clock weight.
    component RollingDigit: Item {
        id: digit

        required property int value
        required property color tint

        implicitWidth: strip.implicitWidth
        implicitHeight: root.digitHeight
        clip: true

        Text {
            id: strip

            y: -digit.value * root.digitHeight
            text: "0\n1\n2\n3\n4\n5\n6\n7\n8\n9"
            color: digit.tint
            horizontalAlignment: Text.AlignHCenter
            font.family: Appearance.fontFamily
            font.pixelSize: root.digitSize
            font.weight: Font.Bold
            lineHeight: root.digitHeight
            lineHeightMode: Text.FixedHeight

            Behavior on y {
                SpringAnimation {
                    spring: 3.5
                    damping: 0.75
                    mass: 1
                }
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
