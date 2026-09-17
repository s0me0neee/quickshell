import QtQuick
import qs.common
import qs.components
import qs.services

// Ring shows the charge, the same dial as the volume. The middle says where the power
// is coming from: a bolt while charging, a plug while topped up on mains, the charge
// level while running on battery. Hover for time left / status.
CircleButton {
    id: root

    readonly property int percent: Math.round(Power.percentage * 100)
    readonly property bool plugged: !Power.discharging && !Power.charging
    readonly property bool low: Power.discharging && !Power.charging && Power.percentage <= 0.15
    readonly property bool warn: Power.discharging && !Power.charging && Power.percentage <= 0.3

    visible: Power.hasBattery && Settings.data.showBattery
    icon: {
        if (Power.charging)
            return Icons.batteryCharging;
        if (root.plugged)
            return Icons.plug;
        return Icons.pick(Icons.battery, Power.percentage);
    }
    iconSize: 18
    // Tinted while it is on mains, so a glance is enough
    fill: {
        if (root.low)
            return Theme.danger;
        if (Power.charging || root.plugged)
            return Theme.accent;
        if (root.warn)
            return Theme.accentSoft;
        return Theme.tonal;
    }
    iconColor: {
        if (root.low)
            return Theme.errorContainerText;
        if (Power.charging || root.plugged)
            return Theme.primaryContainerText;
        if (root.warn)
            return Theme.tertiaryContainerText;
        return Theme.secondaryContainerText;
    }
    // Nothing to click: the ring and the tooltip are the whole widget
    cursorShape: Qt.ArrowCursor
    tooltip: `${root.percent}% · ${Power.status}`

    RingGauge {
        anchors.fill: parent
        anchors.margins: 1
        value: Power.percentage
        color: root.low ? Theme.critical : root.warn ? Theme.tertiary : Theme.primary
        trackColor: Qt.alpha(root.iconColor, 0.2)

        Behavior on value {
            Anim {
                duration: Appearance.animSlow
            }
        }
    }
}
