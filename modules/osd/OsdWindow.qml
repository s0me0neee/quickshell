import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

// The OSD as its own surface, for when a fullscreen window covers the bar and the
// island's morph can't be seen. Sits low on the overlay layer, above the fullscreen
// window, and takes no input.
//
// Only on the focused monitor: `Osd.overlay` is true for a fullscreen window there, so
// drawing this on every screen would put an OSD on monitors that can still see a bar.
PanelWindow {
    id: root

    // Plain 0, bound in Component.onCompleted: a Behavior never runs on a binding's
    // first evaluation, and this window is built at the moment it is needed, so
    // binding it here would have it appear already settled instead of sliding in.
    property real progress: 0

    screen: Hyprland.focusedMonitor?.screen ?? null
    anchors.bottom: true
    margins.bottom: 140
    implicitWidth: panel.width
    implicitHeight: panel.height + slide
    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.namespace: "qs-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    // An empty mask: the surface is there to be looked at, never clicked. Without it a
    // transparent rectangle would eat clicks meant for the fullscreen window under it.
    mask: Region {}

    readonly property int slide: 16

    // Eased reading, same trick as the island's: the raw value steps as the key
    // repeats, this sweeps between the steps
    property real level: Osd.value

    Behavior on level {
        Anim {
            duration: Appearance.animFast
        }
    }

    Component.onCompleted: progress = Qt.binding(() => Osd.overlay ? 1 : 0)

    Behavior on progress {
        Anim {
            duration: Osd.overlay ? Appearance.animNormal : Appearance.animFast
            easing.bezierCurve: Osd.overlay ? Appearance.curveEmphasized : Appearance.curveStandard
        }
    }

    Rectangle {
        id: panel

        // Rises as it fades in
        y: root.slide * (1 - root.progress)
        width: row.implicitWidth + 32
        height: 54
        radius: height / 2
        color: Theme.panel
        border.width: 1
        border.color: Theme.glassEdge
        opacity: root.progress

        Row {
            id: row

            anchors.centerIn: parent
            spacing: Appearance.spacingLarge

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: Osd.icon
                size: 22
                color: Osd.muted ? Theme.critical : Theme.primary
            }

            WavyProgress {
                anchors.verticalCenter: parent.verticalCenter
                width: 150
                wavy: false
                lineWidth: 6
                value: root.level
                color: Osd.muted ? Theme.critical : Theme.primary
            }

            StyledText {
                id: percent

                anchors.verticalCenter: parent.verticalCenter
                // Right-aligned in a "100%"-wide box, so the panel doesn't twitch as
                // the reading passes 10 and 100
                width: percentMetrics.width
                horizontalAlignment: Text.AlignRight
                text: `${Math.round(root.level * 100)}%`
                color: Theme.surfaceText
                font.pixelSize: Appearance.fontSize

                TextMetrics {
                    id: percentMetrics

                    font: percent.font
                    text: "100%"
                }
            }
        }
    }
}
