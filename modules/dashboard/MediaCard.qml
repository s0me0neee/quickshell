import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services

// Media card: art, title, wavy progress, transport controls.
Item {
    id: root

    // True while the card is on screen; position is only refreshed then
    property bool active: false
    // The hub shows the same card, taller and with the album
    property int minHeight: 150
    property bool detailed: false
    readonly property MprisPlayer player: Media.active
    readonly property real length: player?.length ?? 0
    readonly property real position: player?.position ?? 0

    function time(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${(s % 60).toString().padStart(2, "0")}`;
    }

    implicitWidth: 520
    // Grows with its contents: an artist line or a wrapped row of player chips would
    // otherwise push the transport controls off the bottom edge, which the panel clips
    implicitHeight: Math.max(root.minHeight, info.implicitHeight)

    // MPRIS doesn't push position updates: refresh once a second, only while shown and playing
    Timer {
        interval: 1000
        repeat: true
        running: root.active && Media.playing
        onTriggered: root.player?.positionChanged()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 16

        ClippingRectangle {
            Layout.alignment: Qt.AlignVCenter
            // Square, and as tall as the card, so the art stays flush with both edges
            implicitWidth: root.implicitHeight
            implicitHeight: root.implicitHeight
            radius: 22
            color: Theme.accent

            Image {
                anchors.fill: parent
                source: Media.artUrl
                // Decoded well above the drawn size, so high-resolution cover art
                // stays sharp instead of being downscaled to the old 248px
                sourceSize.width: 512
                sourceSize.height: 512
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Icon {
                anchors.centerIn: parent
                visible: Media.artUrl === ""
                text: Icons.music
                size: 40
                color: Theme.primaryContainerText
            }
        }

        ColumnLayout {
            id: info

            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: Media.title || "Nothing playing"
                elide: Text.ElideRight
                font.pixelSize: 17
                font.weight: Font.Bold
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: Media.artist
                elide: Text.ElideRight
                color: Theme.surfaceVariantText
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.detailed && text !== ""
                text: Media.album
                elide: Text.ElideRight
                color: Theme.textDim
                font.pixelSize: Appearance.fontSizeSmall
            }

            // One chip per player, on its own row so a second player can never squeeze
            // the title out. It is never a guess which app the card is driving; with a
            // single player this is just the name badge it was.
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: Appearance.spacingSmall

                Repeater {
                    model: Media.sorted

                    MouseArea {
                        id: chip

                        required property var modelData
                        readonly property bool current: modelData === root.player

                        implicitWidth: Math.min(label.implicitWidth + 16, 150)
                        implicitHeight: 22
                        hoverEnabled: true
                        enabled: Media.manyPlayers
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Media.choose(chip.modelData)

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: chip.current ? Theme.accent : chip.containsMouse ? Theme.glassHover : "transparent"
                            border.width: chip.current ? 0 : 1
                            border.color: Qt.alpha(Theme.surfaceText, 0.25)

                            Behavior on color {
                                CAnim {
                                    duration: Appearance.animFast
                                }
                            }
                        }

                        StyledText {
                            id: label

                            anchors.centerIn: parent
                            width: Math.min(implicitWidth, 134)
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: chip.modelData.identity ?? ""
                            color: chip.current ? Theme.primaryContainerText : Theme.surfaceVariantText
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }

            // Sits in the slack the layout already had between the chips and the progress
            // line, so switching it on never makes the card taller.
            //
            // cava runs only while this is both on screen and playing, and the process is
            // killed rather than idled the moment either stops — see services/Cava.qml.
            Item {
                id: visualiser

                readonly property bool wanted: root.active && Media.playing
                readonly property real slot: width / Cava.bars

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 34
                Layout.bottomMargin: 6
                clip: true

                onWantedChanged: wanted ? Cava.watch() : Cava.unwatch()

                Component.onDestruction: {
                    if (wanted)
                        Cava.unwatch();
                }

                Repeater {
                    model: Cava.bars

                    Rectangle {
                        required property int index
                        readonly property real level: Cava.values[index] ?? 0

                        // No Behavior on height: cava is already sending thirty frames a
                        // second, and easing on top of that only adds lag and redraws
                        x: index * visualiser.slot
                        y: visualiser.height - height
                        width: Math.max(2, visualiser.slot - 4)
                        height: Math.max(3, visualiser.height * level)
                        // Capped by the shorter side, or a quiet bar rounds into an oval
                        radius: Math.min(width, height) / 2
                        color: Theme.primary
                        // Silence fades out altogether rather than leaving a row of dashes
                        // sitting above the progress line, where it reads as a second one
                        opacity: level < 0.02 ? 0 : 0.3 + 0.55 * level
                    }
                }
            }

            WavyProgress {
                Layout.fillWidth: true
                value: root.length > 0 ? root.position / root.length : 0
                // A straight line whether playing or paused
                wavy: false

                MouseArea {
                    anchors.fill: parent
                    enabled: (root.player?.canSeek ?? false) && root.length > 0
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: event => root.player.position = event.x / width * root.length
                }
            }

            RowLayout {
                Layout.fillWidth: true

                StyledText {
                    text: root.time(root.position)
                    color: Theme.textDim
                    font.pixelSize: 11
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    text: root.time(root.length)
                    color: Theme.textDim
                    font.pixelSize: 11
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 14

                Control {
                    visible: root.player?.shuffleSupported ?? false
                    icon: Icons.shuffle
                    on: root.player?.shuffle ?? false
                    onClicked: root.player.shuffle = !root.player.shuffle
                }

                Control {
                    icon: Icons.previous
                    enabled: Media.canGoPrevious
                    onClicked: Media.previous()
                }

                // Play/pause: rounded square while playing, pill while paused
                MouseArea {
                    id: play

                    implicitWidth: 54
                    implicitHeight: 38
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Media.togglePlaying()

                    Rectangle {
                        anchors.fill: parent
                        radius: Media.playing ? 12 : height / 2
                        color: Theme.primary
                        scale: play.pressed ? 0.9 : 1

                        Behavior on radius {
                            Anim {
                                duration: Appearance.animSlow
                                easing.bezierCurve: Appearance.curveExpressive
                            }
                        }

                        Behavior on scale {
                            Anim {
                                duration: Appearance.animNormal
                                easing.bezierCurve: Appearance.curveExpressive
                            }
                        }

                        Icon {
                            anchors.centerIn: parent
                            text: Media.playing ? Icons.pause : Icons.play
                            size: 24
                            color: Theme.primaryText
                        }
                    }
                }

                Control {
                    icon: Icons.next
                    enabled: Media.canGoNext
                    onClicked: Media.next()
                }

                Control {
                    visible: root.player?.loopSupported ?? false
                    icon: root.player?.loopState === MprisLoopState.Track ? Icons.repeatOnce : Icons.repeat
                    on: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                    onClicked: {
                        const next = {
                            [MprisLoopState.None]: MprisLoopState.Playlist,
                            [MprisLoopState.Playlist]: MprisLoopState.Track,
                            [MprisLoopState.Track]: MprisLoopState.None
                        };
                        root.player.loopState = next[root.player.loopState];
                    }
                }
            }
        }
    }

    component Control: MouseArea {
        id: control

        property string icon
        property bool on: false

        implicitWidth: 30
        implicitHeight: 30
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        opacity: enabled ? 1 : 0.35

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: control.on ? Theme.accent : control.containsMouse ? Qt.alpha(Theme.surfaceText, 0.1) : "transparent"
            scale: control.pressed ? 0.85 : 1

            Behavior on color {
                CAnim {
                    duration: Appearance.animFast
                }
            }

            Behavior on scale {
                Anim {
                    duration: Appearance.animNormal
                    easing.bezierCurve: Appearance.curveExpressive
                }
            }
        }

        Icon {
            anchors.centerIn: parent
            text: control.icon
            size: 17
            color: control.on ? Theme.primaryContainerText : Theme.surfaceText
        }
    }
}
