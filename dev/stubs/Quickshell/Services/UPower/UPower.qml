pragma Singleton

import QtQuick
import Preview

QtObject {
    id: root

    // Writable so a test can drive a plug/unplug cycle at runtime; the scenario flags
    // only pick the starting position.
    property bool onBattery: !Preview.scene("charging")

    readonly property UPowerDevice displayDevice: UPowerDevice {
        isLaptopBattery: !Preview.scene("desktop")
        percentage: Preview.scene("lowbattery") ? 0.09 : 0.62
        state: Preview.scene("charging") ? UPowerDeviceState.Charging : UPowerDeviceState.Discharging
        timeToFull: 3300
        timeToEmpty: 8100
    }

    // Mirrors what UPower reports across a real plug/unplug: the daemon moves the
    // device state and the system-wide onBattery flag together.
    function setPluggedIn(plugged: bool, full: bool): void {
        displayDevice.state = plugged ? (full ? UPowerDeviceState.FullyCharged : UPowerDeviceState.Charging) : UPowerDeviceState.Discharging;
        onBattery = !plugged;
    }
}
