import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.common
import qs.components
import qs.services

// The settings half of the bar, in one panel: how bright the screen is and how hard
// the machine is allowed to work. Both used to be a button of their own; neither is
// something you watch, so neither earns a permanent seat.
Popout {
    id: root

    function profileIcon(value: int): string {
        if (value === PowerProfile.Performance)
            return Icons.profilePerformance;
        if (value === PowerProfile.PowerSaver)
            return Icons.profilePowerSaver;
        return Icons.profileBalanced;
    }

    contentWidth: 320

    // A panel can be plugged in or unplugged while the shell runs, and the list is the
    // one thing the level watcher can't tell us about
    onOpenChanged: {
        if (open)
            Brightness.refresh();
    }

    Heading {
        visible: Brightness.available
        text: "Display"
    }

    BigSlider {
        Layout.fillWidth: true
        visible: Brightness.available
        icon: Icons.pick(Icons.brightness, Brightness.brightness)
        value: Brightness.brightness
        onMoved: value => Brightness.set(value)
    }

    // Only worth a list when there is more than one panel to dim
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

    Divider {
        visible: Brightness.available
    }

    Heading {
        text: "Power"
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingSmall

        Repeater {
            model: Power.profiles

            ProfileChip {}
        }
    }

    // Time left, which is the thing the choice above actually moves
    StyledText {
        Layout.fillWidth: true
        Layout.topMargin: 2
        visible: Power.hasBattery
        text: `${Math.round(Power.percentage * 100)}% · ${Power.status}`
        color: Theme.textDim
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Appearance.fontSizeSmall
    }

    component Heading: StyledText {
        font.pixelSize: Appearance.fontSize + 2
        font.weight: Font.DemiBold
    }

    component ProfileChip: Rectangle {
        id: chip

        required property int modelData
        readonly property bool current: Power.profile === modelData

        Layout.fillWidth: true
        implicitHeight: 58
        radius: Appearance.radiusItem
        color: chip.current ? Theme.accent : hover.hovered ? Qt.alpha(Theme.surfaceText, 0.1) : Qt.alpha(Theme.secondaryContainer, 0.3)

        Behavior on color {
            CAnim {
                duration: Appearance.animFast
            }
        }

        HoverHandler {
            id: hover

            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: Power.setProfile(chip.modelData)
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 1

            Icon {
                Layout.alignment: Qt.AlignHCenter
                text: root.profileIcon(chip.modelData)
                size: 20
                color: chip.current ? Theme.primaryContainerText : Theme.surfaceVariantText
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Power.profileName(chip.modelData)
                color: chip.current ? Theme.primaryContainerText : Theme.surfaceVariantText
                font.pixelSize: Appearance.fontSizeSmall
            }
        }
    }
}
