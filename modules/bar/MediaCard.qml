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
    readonly property MprisPlayer player: Media.active
    readonly property real length: player?.length ?? 0
    readonly property real position: player?.position ?? 0

    function time(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return `${Math.floor(s / 60)}:${(s % 60).toString().padStart(2, "0")}`;
    }

    implicitWidth: 446
    implicitHeight: 124

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
            implicitWidth: 124
            implicitHeight: 124
            radius: 18
            color: Theme.accent

            Image {
                anchors.fill: parent
                source: Media.artUrl
                sourceSize.width: 248
                sourceSize.height: 248
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
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing

                StyledText {
                    Layout.fillWidth: true
                    text: Media.title || "Nothing playing"
                    font.pixelSize: 17
                    font.weight: Font.Bold
                }

                Rectangle {
                    visible: chip.text !== ""
                    implicitWidth: chip.implicitWidth + 16
                    implicitHeight: 22
                    radius: 11
                    color: Theme.accent

                    StyledText {
                        id: chip

                        anchors.centerIn: parent
                        text: root.player?.identity ?? ""
                        color: Theme.primaryContainerText
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: Media.artist
                color: Theme.surfaceVariantText
            }

            Item {
                Layout.fillHeight: true
            }

            WavyProgress {
                Layout.fillWidth: true
                value: root.length > 0 ? root.position / root.length : 0
                wavy: Media.playing

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
                            size: 20
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
