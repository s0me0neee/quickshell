import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common
import qs.components
import qs.services

// Ring shows the volume. Scroll: ±2%. Right click: mute. Middle click: pavucontrol.
// Left click: sound panel.
CircleButton {
    id: root

    required property QtObject bar

    property bool panelOpen: false
    readonly property bool panelLive: panelOpen || panelLinger.running

    onPanelOpenChanged: {
        if (panelOpen)
            panelLinger.stop();
        else
            panelLinger.restart();
        if (panelLoader.item)
            panelLoader.item.open = root.panelOpen;
    }

    Timer {
        id: panelLinger

        interval: Appearance.animNormal + 80
    }

    // Bluetooth wins over headphones: a wireless headset is both, and which radio the
    // sound is going out of is the thing worth knowing at a glance
    readonly property string glyph: {
        if (Audio.muted)
            return Icons.volumeMuted;
        if (Audio.bluetooth)
            return Icons.bluetooth;
        if (Audio.headphones)
            return Icons.headphones;
        return Icons.pick(Icons.volume, Audio.volume);
    }

    visible: Settings.data.showVolume
    icon: glyph
    iconSize: 16
    iconColor: Audio.muted ? Theme.critical : Theme.secondaryContainerText
    active: root.panelOpen
    tooltip: root.panelOpen ? "" : `Volume ${Math.round(Audio.volume * 100)}%${Audio.muted ? " · muted" : ""}`
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            Audio.toggleMute();
        else if (mouse.button === Qt.MiddleButton)
            Audio.openMixer();
        else
            root.panelOpen = !root.panelOpen;
    }
    onWheel: event => Audio.step(event.angleDelta.y > 0 ? 0.02 : -0.02)

    RingGauge {
        anchors.fill: parent
        anchors.margins: 1
        value: Audio.volume
        color: Audio.muted ? Theme.critical : Theme.primary

        Behavior on value {
            Anim {
                duration: Appearance.animFast
            }
        }
    }

    LazyLoader {
        id: panelLoader

        active: root.panelLive

        Popout {
            id: popout

            target: root
            bar: root.bar
            contentWidth: 320

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing

                StyledText {
                    Layout.fillWidth: true
                    text: "Sound"
                    font.pixelSize: Appearance.fontSize + 2
                    font.weight: Font.DemiBold
                }

                CircleButton {
                    visible: Audio.hasMic
                    icon: Audio.micMuted ? Icons.micMuted : Icons.mic
                    fill: Audio.micMuted ? Theme.danger : Theme.tonal
                    iconColor: Audio.micMuted ? Theme.errorContainerText : Theme.secondaryContainerText
                    tooltip: Audio.micMuted ? "Unmute microphone" : "Mute microphone"
                    onClicked: Audio.toggleMicMute()
                }

                CircleButton {
                    icon: root.glyph
                    fill: Audio.muted ? Theme.danger : Theme.tonal
                    iconColor: Audio.muted ? Theme.errorContainerText : Theme.secondaryContainerText
                    tooltip: Audio.muted ? "Unmute" : "Mute"
                    onClicked: Audio.toggleMute()
                }
            }

            BigSlider {
                Layout.fillWidth: true
                icon: root.glyph
                muted: Audio.muted
                value: Audio.volume
                onMoved: value => Audio.setVolume(value)
            }

            Heading {
                text: "Output"
            }

            Repeater {
                model: Audio.sinks

                ListItem {
                    required property var modelData

                    icon: modelData === Audio.sink ? Icons.radioOn : Icons.radioOff
                    highlighted: modelData === Audio.sink
                    label: modelData.description || modelData.nickname || modelData.name
                    onActivated: Audio.setDefault(modelData)
                }
            }

            // Microphone: the same controls, only shown when there is one
            Divider {
                visible: Audio.hasMic
            }

            Heading {
                visible: Audio.hasMic
                text: "Input"
            }

            BigSlider {
                Layout.fillWidth: true
                visible: Audio.hasMic
                icon: Audio.micMuted ? Icons.micMuted : Icons.mic
                muted: Audio.micMuted
                value: Audio.micVolume
                onMoved: value => Audio.setMicVolume(value)
            }

            Repeater {
                model: Audio.hasMic ? Audio.sources : []

                ListItem {
                    required property var modelData

                    icon: modelData === Audio.source ? Icons.radioOn : Icons.radioOff
                    highlighted: modelData === Audio.source
                    label: modelData.description || modelData.nickname || modelData.name
                    onActivated: Audio.setDefaultSource(modelData)
                }
            }

            // Whatever is making noise right now, one slider each
            Divider {
                visible: Audio.streams.length > 0
            }

            Heading {
                visible: Audio.streams.length > 0
                text: "Apps"
            }

            Repeater {
                model: Audio.streams

                StreamRow {}
            }

            Divider {}

            ListItem {
                icon: Icons.mixer
                label: "Open mixer"
                onActivated: {
                    popout.open = false;
                    Audio.openMixer();
                }
            }
        }
    }

    Connections {
        target: panelLoader

        // Created a moment after `active` flips; open it then, animation and all
        function onItemChanged(): void {
            if (panelLoader.item)
                panelLoader.item.open = root.panelOpen;
        }
    }

    Connections {
        target: panelLoader.item

        function onOpenChanged(): void {
            if (panelLoader.item && root.panelOpen !== panelLoader.item.open)
                root.panelOpen = panelLoader.item.open;
        }
    }

    component Heading: StyledText {
        Layout.topMargin: Appearance.spacingSmall
        color: Theme.surfaceVariantText
        font.pixelSize: Appearance.fontSizeSmall
    }

    // One playing app: name and level on top, its own slider under it
    component StreamRow: ColumnLayout {
        id: stream

        required property var modelData

        Layout.fillWidth: true
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacingSmall

            Icon {
                text: stream.modelData.audio?.muted ? Icons.volumeMuted : Icons.speaker
                size: 14
                color: stream.modelData.audio?.muted ? Theme.critical : Theme.surfaceVariantText

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Audio.toggleStreamMute(stream.modelData)
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: Audio.streamName(stream.modelData)
                elide: Text.ElideRight
                font.pixelSize: Appearance.fontSizeSmall
            }

            StyledText {
                text: `${Math.round((stream.modelData.audio?.volume ?? 0) * 100)}%`
                color: Theme.surfaceVariantText
                font.pixelSize: Appearance.fontSizeSmall
            }
        }

        BigSlider {
            Layout.fillWidth: true
            implicitHeight: 24
            icon: ""
            label: ""
            muted: stream.modelData.audio?.muted ?? false
            value: stream.modelData.audio?.volume ?? 0
            onMoved: value => Audio.setStreamVolume(stream.modelData, value)
        }
    }
}
