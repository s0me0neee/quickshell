import QtQuick
import qs.common
import qs.components
import qs.services

// Ring shows the charge, the same dial as the volume. Hover for time left / status.
CircleButton {
    id: root

    readonly property int percent: Math.round(Power.percentage * 100)
    readonly property bool low: Power.onBattery && !Power.charging && Power.percentage <= 0.15
    readonly property bool warn: Power.onBattery && !Power.charging && Power.percentage <= 0.3

    visible: Power.hasBattery
    icon: Power.charging ? Icons.batteryCharging : Icons.pick(Icons.battery, Power.percentage)
    iconSize: 12
    iconColor: root.low ? Theme.critical : Theme.secondaryContainerText
    // Nothing to click: the ring and the tooltip are the whole widget
    cursorShape: Qt.ArrowCursor
    tooltip: `${root.percent}% · ${Power.status}`

    RingGauge {
        anchors.fill: parent
        anchors.margins: 1
        value: Power.percentage
        color: root.low ? Theme.critical : root.warn ? Theme.tertiary : Theme.primary

        Behavior on value {
            Anim {
                duration: Appearance.animSlow
            }
        }
    }
}
