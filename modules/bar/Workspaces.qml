import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.common
import qs.components

// Workspace dots. Filled = has windows, faint = empty. Workspaces 1-5 always show;
// more appear if they exist.
//
// Every dot owns a fixed slot, so no dot ever moves and the group never changes width:
// switching workspaces slides a capsule between slots instead of resizing the dots,
// and hover scales a dot in place. The capsule animates its leading and trailing edge
// at different speeds (caelestia's trick), so it stretches as it travels and settles
// back down on arrival.
Pill {
    id: root

    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? 1
    readonly property int count: Math.max(5, ...Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === monitor).map(w => w.id))
    // -1 while a special workspace is up: the capsule hides, the group stays put
    readonly property int activeIndex: activeId >= 1 && activeId <= count ? activeId - 1 : -1

    readonly property bool activeUrgent: Hyprland.workspaces.values.find(w => w.id === activeId)?.urgent ?? false

    readonly property int dotSize: 15
    readonly property int slot: 29

    padding: 13
    spacing: 0
    implicitWidth: count * slot + padding * 2
    onScrolled: delta => Hyprland.dispatch(`workspace ${delta > 0 ? "e-1" : "e+1"}`)
    onActiveIndexChanged: track.runAnim()

    Item {
        id: track

        // The capsule's edges, animated separately
        property real start: 0
        property real end: root.slot

        readonly property int lead: Appearance.animSlow
        readonly property int trail: Appearance.animSlow * 1.5

        function runAnim(): void {
            if (root.activeIndex < 0)
                return;
            const to = root.activeIndex * root.slot;
            const goingLeft = to < start;
            startAnim.stop();
            endAnim.stop();
            startAnim.to = to;
            endAnim.to = to + root.slot;
            // The edge that leads gets there first; the other one drags behind
            startAnim.duration = goingLeft ? lead : trail;
            endAnim.duration = goingLeft ? trail : lead;
            startAnim.start();
            endAnim.start();
        }

        Layout.alignment: Qt.AlignVCenter
        implicitWidth: root.count * root.slot
        implicitHeight: root.dotSize
        Component.onCompleted: {
            if (root.activeIndex >= 0) {
                start = root.activeIndex * root.slot;
                end = start + root.slot;
            }
        }

        Rectangle {
            id: capsule

            x: track.start
            width: Math.max(0, track.end - track.start)
            height: root.dotSize
            radius: height / 2
            color: root.activeUrgent ? Theme.critical : Theme.primary
            visible: root.activeIndex >= 0

            Behavior on color {
                CAnim {
                    duration: Appearance.animNormal
                }
            }
        }

        Anim on start {
            id: startAnim
        }

        Anim on end {
            id: endAnim
        }

        Repeater {
            model: root.count

            MouseArea {
                id: dot

                required property int index
                readonly property int wsId: index + 1
                readonly property HyprlandWorkspace ws: Hyprland.workspaces.values.find(w => w.id === wsId) ?? null
                readonly property bool isActive: root.activeIndex === index
                readonly property bool occupied: (ws?.toplevels.values.length ?? 0) > 0

                x: index * root.slot
                width: root.slot
                height: root.dotSize
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(`workspace ${wsId}`)

                Rectangle {
                    anchors.centerIn: parent
                    width: root.dotSize
                    height: root.dotSize
                    radius: height / 2
                    // The capsule stands in for the active dot
                    opacity: dot.isActive ? 0 : 1
                    // Hover swells the dot in place, so its neighbours never move
                    scale: dot.containsMouse ? 1.3 : 1
                    color: {
                        if (dot.ws?.urgent)
                            return Theme.critical;
                        if (dot.occupied)
                            return Theme.surfaceText;
                        return Qt.alpha(Theme.surfaceText, dot.containsMouse ? 0.5 : 0.28);
                    }

                    Behavior on color {
                        CAnim {
                            duration: Appearance.animNormal
                        }
                    }

                    Behavior on opacity {
                        Anim {
                            duration: Appearance.animFast
                        }
                    }

                    Behavior on scale {
                        Anim {
                            duration: Appearance.animFast
                        }
                    }
                }
            }
        }
    }
}
