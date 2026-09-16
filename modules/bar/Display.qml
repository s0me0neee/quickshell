import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// Ring shows the backlight level, the same dial as the volume and the battery.
// Scroll: ±5%. Left click: display panel. Named for the panel rather than the service,
// so the file doesn't shadow the Brightness singleton it reads.
CircleButton {
    id: root

    required property QtObject bar

    readonly property string glyph: Icons.pick(Icons.brightness, Brightness.brightness)

    visible: Brightness.available
    icon: glyph
    iconSize: 16
    active: popout.open
    tooltip: popout.open ? "" : `Brightness ${Brightness.percent}%`
    onClicked: popout.toggle()
    onWheel: event => Brightness.step(event.angleDelta.y > 0 ? 0.05 : -0.05)

    RingGauge {
        anchors.fill: parent
        anchors.margins: 1
        value: Brightness.brightness
        color: Theme.primary

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

        // Nothing tells us when the backlight moves behind our back, so opening the
        // panel is the moment to re-read it
        onOpenChanged: {
            if (open)
                Brightness.refresh();
        }

        StyledText {
            text: "Display"
            font.pixelSize: Appearance.fontSize + 2
            font.weight: Font.DemiBold
        }

        BigSlider {
            Layout.fillWidth: true
            icon: root.glyph
            value: Brightness.brightness
            onMoved: value => Brightness.set(value)
        }

        // Only worth a list when there is more than one panel to dim
        Divider {
            visible: Brightness.devices.length > 1
        }

        StyledText {
            Layout.topMargin: Appearance.spacingSmall
            visible: Brightness.devices.length > 1
            text: "Backlight"
            color: Theme.surfaceVariantText
            font.pixelSize: Appearance.fontSizeSmall
        }

        Repeater {
            model: Brightness.devices.length > 1 ? Brightness.devices : []

            ListItem {
                required property var modelData

                icon: modelData.name === Brightness.device ? Icons.radioOn : Icons.radioOff
                highlighted: modelData.name === Brightness.device
                label: modelData.name
                onActivated: Brightness.setDevice(modelData.name)
            }
        }
    }
}
