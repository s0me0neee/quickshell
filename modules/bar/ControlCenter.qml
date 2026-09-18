import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.common
import qs.components
import qs.services

// The switches, and the two settings with no button of their own.
//
// The split with the rest of the bar: a tile here is a switch, and the button next to
// it holds the detail — Wi-Fi's networks live under the network icon, the microphone's
// level under the volume one. Brightness, the power profile and Bluetooth's devices
// have nowhere else to be, so they are here in full.
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
    // one thing the level watcher can't tell us about.
    //
    // Connections rather than a handler on the root: a handler here would replace
    // Popout's own onOpenChanged, which is what registers this as the open popout and
    // closes any other one
    Connections {
        target: root

        function onOpenChanged(): void {
            if (root.open)
                Brightness.refresh();
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: 2
        rowSpacing: Appearance.spacingSmall
        columnSpacing: Appearance.spacingSmall

        Tile {
            icon: Network.wifiEnabled ? Icons.pick(Icons.wifi, Network.strength) : Icons.wifiOff
            label: "Wi-Fi"
            detail: Network.wifiEnabled ? (Network.wifiNetwork?.name ?? "Not connected") : "Off"
            on: Network.wifiEnabled
            enabled: !Network.wifiHardwareBlocked
            onActivated: Network.setWifiEnabled(!Network.wifiEnabled)
        }

        Tile {
            visible: Bluetooth.available
            icon: Bluetooth.enabled ? Icons.bluetoothOn : Icons.bluetoothOff
            label: "Bluetooth"
            detail: Bluetooth.status
            on: Bluetooth.enabled
            onActivated: Bluetooth.setEnabled(!Bluetooth.enabled)
        }

        // Muted is the state worth shouting about, so that is the one that lights up
        Tile {
            visible: Audio.hasMic
            icon: Audio.micMuted ? Icons.micMuted : Icons.mic
            label: "Microphone"
            detail: Audio.micMuted ? "Muted" : `${Math.round(Audio.micVolume * 100)}%`
            alert: Audio.micMuted
            onActivated: Audio.toggleMicMute()
        }

        // The bell does this on a right click, which nobody discovers
        Tile {
            icon: Notifs.dnd ? Icons.notifications["dnd-none"] : Icons.notifications["none"]
            label: "Do not disturb"
            detail: Notifs.dnd ? "On" : Notifs.count > 0 ? `${Notifs.count} waiting` : "Off"
            on: Notifs.dnd
            onActivated: Notifs.toggleDnd()
        }

        // hypridle locks at 10 minutes and suspends at 30, which is wrong for anything
        // you are watching rather than doing.
        // Spans the row: five tiles in two columns leaves one looking stranded
        Tile {
            Layout.columnSpan: 2
            icon: Idle.enabled ? Icons.coffee : Icons.sleep
            label: "Keep awake"
            detail: Idle.status
            on: Idle.enabled
            onActivated: Idle.toggle()
        }
    }

    SubHeading {
        visible: btList.visible
        text: "Devices"
    }

    ListView {
        id: btList

        Layout.fillWidth: true
        // Grows with the list, then scrolls, so a well-paired machine can't push the
        // brightness slider off the bottom of the screen
        Layout.preferredHeight: Math.min(contentHeight, 180)
        visible: Bluetooth.enabled && Bluetooth.devices.length > 0
        clip: true
        model: Bluetooth.devices

        delegate: ListItem {
            required property var modelData

            width: ListView.view.width
            icon: Icons.bluetoothDevice(modelData.icon ?? "")
            label: Bluetooth.nameOf(modelData)
            subtitle: Bluetooth.stateOf(modelData)
            highlighted: modelData.connected
            onActivated: Bluetooth.toggle(modelData)
        }
    }

    Divider {
        visible: Brightness.available
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
    SubHeading {
        visible: Brightness.devices.length > 1
        text: "Backlight"
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

    Divider {}

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

    Divider {}

    // The way into the settings window. No bar button of its own: this is not something
    // you open often enough to spend a seat on
    ListItem {
        icon: Icons.settings
        label: "Settings"
        onActivated: {
            root.open = false;
            Settings.open();
        }

        Icon {
            text: Icons.chevronRight
            size: 16
            color: Theme.surfaceVariantText
        }
    }

    component Heading: StyledText {
        font.pixelSize: Appearance.fontSize + 2
        font.weight: Font.DemiBold
    }

    component SubHeading: StyledText {
        Layout.topMargin: Appearance.spacingSmall
        color: Theme.surfaceVariantText
        font.pixelSize: Appearance.fontSizeSmall
    }

    // A switch: the name, what it is doing right now, and a fill that says on or off
    component Tile: Rectangle {
        id: tile

        property string icon
        property string label
        property string detail
        property bool on: false
        // For a state that is worth a flag rather than a highlight, like a muted mic
        property bool alert: false
        readonly property color front: tile.alert ? Theme.errorContainerText : tile.on ? Theme.primaryContainerText : Theme.surfaceVariantText

        signal activated

        Layout.fillWidth: true
        implicitHeight: 58
        radius: Appearance.radiusItem + 2
        opacity: tile.enabled ? 1 : 0.5
        color: {
            if (tile.alert)
                return Theme.danger;
            if (tile.on)
                return Theme.accent;
            return hover.hovered ? Qt.alpha(Theme.surfaceText, 0.1) : Qt.alpha(Theme.secondaryContainer, 0.3);
        }

        Behavior on color {
            CAnim {
                duration: Appearance.animFast
            }
        }

        HoverHandler {
            id: hover

            enabled: tile.enabled
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            enabled: tile.enabled
            onTapped: tile.activated()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.spacingLarge - 2
            anchors.rightMargin: Appearance.spacing
            spacing: Appearance.spacing + 2

            Icon {
                text: tile.icon
                size: 20
                color: tile.front
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: tile.label
                    color: tile.front
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.DemiBold
                }

                StyledText {
                    Layout.fillWidth: true
                    text: tile.detail
                    color: Qt.alpha(tile.front, 0.7)
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.fontSizeSmall - 1
                }
            }
        }
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
