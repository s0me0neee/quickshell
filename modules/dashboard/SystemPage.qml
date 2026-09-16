import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// What the machine is doing: two dials in the same language as the volume and battery
// rings, and the handful of lines worth knowing underneath.
//
// Takes a reader on SysStats while it is on screen and drops it when it leaves, so
// /proc is only read while somebody is looking at it.
ColumnLayout {
    id: root

    // Whether this page is the one on show. The dashboard drives it; the timer follows
    property bool active: false

    onActiveChanged: {
        if (active)
            SysStats.watch();
        else
            SysStats.unwatch();
    }

    Component.onDestruction: {
        if (active)
            SysStats.unwatch();
    }

    spacing: Appearance.spacing

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacingSmall
        spacing: Appearance.spacing

        // The ring already says the percentage, so the line under it says the thing the
        // ring can't: how deep the queue is, which is what tells a busy machine from a
        // wedged one
        Dial {
            icon: Icons.cpu
            label: "CPU"
            value: SysStats.cpu
            detail: `load ${SysStats.loadAverage.toFixed(2)}`
        }

        Dial {
            icon: Icons.memory
            label: "Memory"
            value: SysStats.memory
            detail: SysStats.memoryText
        }
    }

    Divider {
        Layout.topMargin: Appearance.spacingSmall
    }

    Line {
        label: "Uptime"
        value: SysStats.uptimeText
    }

    Line {
        label: "Battery"
        visible: Power.hasBattery
        value: `${Math.round(Power.percentage * 100)}% · ${Power.status}`
    }

    Line {
        label: "Network"
        value: Network.connected ? `${Network.name}${Network.ipAddress ? ` · ${Network.ipAddress}` : ""}` : "Not connected"
    }

    // A ring with the figure in the middle, the way the bar draws volume and charge.
    //
    // A plain Item rather than a ColumnLayout as the root: a layout nested straight into
    // another layout sizes itself from its contents and ignores the space it was given,
    // which left both dials huddled at the left of the row.
    component Dial: Item {
        id: dial

        property string icon
        property string label
        property string detail
        property real value: 0

        readonly property color tone: value > 0.9 ? Theme.critical : value > 0.7 ? Theme.tertiary : Theme.primary

        Layout.fillWidth: true
        implicitHeight: stack.implicitHeight

        ColumnLayout {
            id: stack

            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 2

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 78
                implicitHeight: 78

                RingGauge {
                    anchors.fill: parent
                    lineWidth: 5
                    value: dial.value
                    color: dial.tone

                    Behavior on value {
                        Anim {
                            duration: Appearance.animNormal
                        }
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 0

                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        text: dial.icon
                        size: 15
                        color: Theme.surfaceVariantText
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: `${Math.round(dial.value * 100)}%`
                        font.pixelSize: Appearance.fontSize + 1
                        font.weight: Font.DemiBold
                    }
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: dial.label
                color: Theme.surfaceText
                font.pixelSize: Appearance.fontSizeSmall
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: dial.detail
                color: Theme.textDim
                font.pixelSize: Appearance.fontSizeSmall - 1
            }
        }
    }

    component Line: RowLayout {
        id: line

        property string label
        property string value

        Layout.fillWidth: true
        spacing: Appearance.spacing

        StyledText {
            text: line.label
            color: Theme.surfaceVariantText
            font.pixelSize: Appearance.fontSizeSmall
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
            text: line.value
            elide: Text.ElideRight
            font.pixelSize: Appearance.fontSizeSmall
        }
    }
}
