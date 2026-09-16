import QtQuick
import Quickshell
import qs.common
import qs.components
import qs.services

// Center island, after Clavis's Keystone: a rolling clock that grows sideways to
// carry the current track, and expands into the full media card on hover. Each
// digit is a 0-9 strip that springs to its place. Click the clock for the date,
// the track to play/pause; scroll the track to change song.
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

    readonly property int padding: 14
    readonly property int gap: 12
    readonly property int digitSize: 22
    readonly property real digitHeight: 27
    // Hours carry the text color, minutes the wallpaper accent
    readonly property color hourColor: Theme.surfaceText
    readonly property color minuteColor: Theme.primary

    readonly property int h0: Math.floor(clock.hours / 10)
    readonly property int h1: clock.hours % 10
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

    // Ticks once a minute, not once a second
    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Row {
        id: content

        anchors.centerIn: parent
        spacing: 0

        // Now playing: art, title, and the gap before the clock
        Item {
            id: mediaChip

            // Animated here rather than on the pill, so the pill's width always
            // matches its contents exactly instead of trailing them
            property real fullWidth: mediaRow.implicitWidth + root.gap

            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(fullWidth * root.mediaProgress)
            height: root.digitHeight
            visible: width > 0
            opacity: root.mediaProgress
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
                    size: 12
                    color: Theme.primary
                }

                // The old title slides up and out, the new one rises into its place,
                // so a track change is the only thing that ever animates here
                Item {
                    id: titleClip

                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: titleText.width
                    implicitHeight: 19
                    clip: true

                    StyledText {
                        id: titleText

                        // Held rather than bound: the outgoing title has to stay on
                        // screen while it leaves
                        property string pending: Media.title

                        width: Math.min(implicitWidth, 260)
                        height: titleClip.height
                        color: Media.playing ? Theme.surfaceText : Qt.alpha(Theme.surfaceText, 0.55)
                        font.pixelSize: Appearance.fontSize
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
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Media.togglePlaying()
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
                    text: Qt.formatDate(clock.date, "ddd dd MMM")
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

                    RollingDigit {
                        value: root.h0
                        tint: root.hourColor
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
                onClicked: root.showDate = !root.showDate
            }
        }
    }

    Tooltip {
        target: clockRow
        text: Qt.formatDate(clock.date, "dddd, d MMMM yyyy")
        show: clockMouse.containsMouse && !root.showDate
    }

    // Hovering the track expands the island into the full card: art, progress and
    // controls. It takes no focus grab, so it never swallows a click meant elsewhere.
    Popout {
        id: card

        target: mediaChip
        bar: root.bar
        contentWidth: 520
        grabsFocus: false

        MediaCard {
            active: card.open
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
