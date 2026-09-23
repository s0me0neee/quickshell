pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Services.UPower
import qs.services

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

    // Warn levels, as whole percent
    readonly property int lowLevel: 20
    readonly property int criticalLevel: 10

    // One flag per threshold, so a reading that jitters across the line doesn't warn
    // twice. Both re-arm when the charger goes back in — that is the only reset.
    property bool warnedLow: false
    property bool warnedCritical: false

    // Event-driven off UPower: no timer, nothing polling. Runs on every reported
    // change, which is also what catches the charger being pulled while already low.
    onPercentageChanged: checkCharge()
    onDischargingChanged: checkCharge()
    onChargingChanged: checkCharge()

    function checkCharge(): void {
        if (!hasBattery)
            return;

        if (charging || !discharging) {
            warnedLow = false;
            warnedCritical = false;
            return;
        }

        const pct = Math.round(percentage * 100);

        if (pct <= criticalLevel) {
            if (warnedCritical)
                return;
            warnedCritical = true;
            // Passing the low mark too, so unplugging at 8% doesn't stack both warnings
            warnedLow = true;
            // Persists (timeout 0): this one should still be on screen when you look up
            Notifs.notify("Battery critically low", timeLeft > 0 ? `${pct}% — about ${formatTime(timeLeft)} left. Plug in now.` : `${pct}% left. Plug in now.`, NotificationUrgency.Critical, "battery-caution-symbolic", 0);
        } else if (pct <= lowLevel && !warnedLow) {
            warnedLow = true;
            Notifs.notify("Battery low", timeLeft > 0 ? `${pct}% — about ${formatTime(timeLeft)} left.` : `${pct}% left.`, NotificationUrgency.Normal, "battery-low-symbolic", -1);
        }
    }
}
