pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property UPowerDevice battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    readonly property real percentage: battery?.percentage ?? 0
    readonly property bool charging: battery?.state === UPowerDeviceState.Charging || battery?.state === UPowerDeviceState.PendingCharge
    readonly property bool full: battery?.state === UPowerDeviceState.FullyCharged
    // UPower calls this onBattery, but a property named onX is silently swallowed as a
    // handler for the sibling property x — and `battery` is declared right above, so the
    // binding never connected and this read false forever.
    readonly property bool discharging: UPower.onBattery
    // Seconds until empty (discharging) or full (charging); 0 when unknown
    readonly property real timeLeft: charging ? (battery?.timeToFull ?? 0) : (battery?.timeToEmpty ?? 0)

    readonly property int profile: PowerProfiles.profile
    // Slowest to fastest. Not every machine offers the top one
    readonly property var profiles: PowerProfiles.hasPerformanceProfile ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance] : [PowerProfile.PowerSaver, PowerProfile.Balanced]

    function setProfile(value: int): void {
        PowerProfiles.profile = value;
    }

    function cycleProfile(): void {
        setProfile(profiles[(profiles.indexOf(PowerProfiles.profile) + 1) % profiles.length]);
    }

    function profileName(value: int): string {
        if (value === PowerProfile.Performance)
            return "Performance";
        if (value === PowerProfile.PowerSaver)
            return "Power saver";
        return "Balanced";
    }

    // Human status for the battery pill, e.g. "2h 15m left", "Charging", "Full"
    readonly property string status: {
        if (full)
            return "Full";
        if (charging)
            return timeLeft > 0 ? `${formatTime(timeLeft)} to full` : "Charging";
        if (!discharging)
            return "Plugged in";
        // UPower needs a little while on battery before it can estimate
        return timeLeft > 0 ? `${formatTime(timeLeft)} left` : "Estimating…";
    }

    function formatTime(seconds: real): string {
        const h = Math.floor(seconds / 3600);
        const m = Math.floor(seconds % 3600 / 60);
        return h > 0 ? `${h}h ${m}m` : `${m}m`;
    }
}
