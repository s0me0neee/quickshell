import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.components

// Top bar: floating glass groups on a transparent strip. Left and right are anchored
// to the edges; the island floats in the middle and morphs as media comes and goes.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: bar

        required property ShellScreen modelData

        screen: modelData
        anchors.top: true
        anchors.left: true
        anchors.right: true
        margins.top: Appearance.barMarginTop
        margins.left: Appearance.barMarginSide
        margins.right: Appearance.barMarginSide
        implicitHeight: Appearance.barHeight
        // A pixel less than it occupies, so the gap under the bar is as tight as the
        // one above it
        exclusiveZone: Appearance.barMarginTop + Appearance.barHeight - 1
        color: "transparent"

        WlrLayershell.namespace: "qs-bar"
        WlrLayershell.layer: WlrLayer.Top

        // Clicking the bar itself, rather than one of its buttons, folds any open
        // popout back. Declared first, so the groups above it take their clicks.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: PopoutState.current = null
        }

        RowLayout {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Appearance.groupGap

            Workspaces {
                screen: bar.screen
            }

            Pill {
                NotificationBell {
                    bar: bar
                }
            }
        }

        Island {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            bar: bar
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Appearance.groupGap

            Tray {
                bar: bar
            }

            Pill {
                NetworkStatus {
                    bar: bar
                }

                Volume {
                    bar: bar
                }

                Battery {}

                PowerProfile {}

                PowerButton {}
            }
        }
    }
}
