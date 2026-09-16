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

    readonly property string glyph: {
        if (Audio.muted)
            return Icons.volumeMuted;
        if (Audio.headphones)
            return Icons.headphones;
        return Icons.pick(Icons.volume, Audio.volume);
    }

    icon: glyph
    iconSize: 12
    iconColor: Audio.muted ? Theme.critical : Theme.secondaryContainerText
    active: popout.open
    tooltip: popout.open ? "" : `Volume ${Math.round(Audio.volume * 100)}%${Audio.muted ? " · muted" : ""}`
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            Audio.toggleMute();
        else if (mouse.button === Qt.MiddleButton)
            Audio.openMixer();
        else
            popout.toggle();
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

        StyledText {
            Layout.topMargin: Appearance.spacingSmall
            text: "Output"
            color: Theme.surfaceVariantText
            font.pixelSize: Appearance.fontSizeSmall
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
