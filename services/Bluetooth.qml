pragma Singleton

import QtQuick
import Quickshell
// Aliased: the singleton in there is also called Bluetooth, and so is this file
import Quickshell.Bluetooth as Bluez

// The radio and the devices already paired with it. Hunting for new ones is still
// bluetoothctl's job; this is for turning it on and picking up a headset.
Singleton {
    id: root

    readonly property var adapter: Bluez.Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter?.enabled ?? false

    // Connected first, then the rest, each alphabetical. Devices the adapter merely sees
    // are left out: an unpaired stranger is not something to offer in a control center
    readonly property var devices: (adapter?.devices.values ?? []).filter(d => d.paired || d.connected).sort((a, b) => (b.connected - a.connected) || root.nameOf(a).localeCompare(root.nameOf(b)))
    readonly property var connected: devices.filter(d => d.connected)

    // The line under "Bluetooth" on its tile
    readonly property string status: {
        if (!available)
            return "No adapter";
        if (!enabled)
            return "Off";
        if (connected.length === 1)
            return nameOf(connected[0]);
        if (connected.length > 1)
            return `${connected.length} devices`;
        return "On";
    }

    function setEnabled(value: bool): void {
        if (adapter)
            adapter.enabled = value;
    }

    function toggle(device: var): void {
        if (device.connected)
            device.disconnect();
        else
            device.connect();
    }

    function nameOf(device: var): string {
        return device?.deviceName || device?.name || device?.address || "";
    }

    function stateOf(device: var): string {
        switch (device?.state) {
        case Bluez.BluetoothDeviceState.Connecting:
            return "Connecting…";
        case Bluez.BluetoothDeviceState.Disconnecting:
            return "Disconnecting…";
        case Bluez.BluetoothDeviceState.Connected:
            return "Connected";
        }
        return device?.pairing ? "Pairing…" : "Paired";
    }
}
