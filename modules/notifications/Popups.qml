import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

// Notification popups, stacked under the right end of the bar. They slide in from the
// edge and leave the same way; an entry stays in the list after its popup goes.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property ShellScreen modelData

        // Entries being drawn: everything popping up, plus the ones still sliding out
        property var shown: []

        function sync(): void {
            const live = Notifs.popups;
            const kept = shown.filter(n => live.includes(n) || !n.closed);
            for (const entry of live)
                if (!kept.includes(entry))
                    kept.unshift(entry);
            shown = kept;
            sweep.restart();
        }

        // Entries that have stopped being popups are still sliding out. Sweeping them on
        // a timer rather than from the animation keeps the stack honest whatever the
        // delegates do: Qt never emits finished() for an animation inside a Behavior, and
        // a leaving card can be rebuilt out from under its own animation.
        Timer {
            id: sweep

            interval: Appearance.animNormal + 80
            onTriggered: win.shown = win.shown.filter(n => Notifs.popups.includes(n))
        }

        screen: modelData
        visible: shown.length > 0
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        anchors.top: true
        anchors.right: true
        margins.top: Appearance.barMarginTop + Appearance.barHeight + Appearance.popoutGap
        margins.right: Appearance.barMarginSide
        implicitWidth: 400
        // Fixed, deliberately: sizing the window to the stack resized a blurred layer
        // surface on every animation frame, which is what made the popups stutter and
        // smear. The stack animates inside a window that never changes size.
        implicitHeight: (modelData.height ?? 1080) - margins.top - 20

        WlrLayershell.namespace: "qs-notifications"
        WlrLayershell.layer: WlrLayer.Top

        // Only the cards take clicks; the empty space below them doesn't
        mask: Region {
            item: column
        }

        Connections {
            target: Notifs

            function onPopupsChanged(): void {
                win.sync();
            }
        }

        Component.onCompleted: sync()

        Column {
            id: column

            width: parent.width
            spacing: Appearance.spacing

            // ScriptModel, not the array itself: a Repeater on a plain array rebuilds every
            // delegate whenever the array is reassigned, which restarts each card's
            // animation every time any other notification arrives or leaves
            Repeater {
                model: ScriptModel {
                    values: win.shown
                }

                Item {
                    id: slot

                    required property NotifEntry modelData

                    // 1 while the popup is up, 0 once it has left. Starts at 0 and is bound
                    // once built: an entry is always created while its popup is up, and a
                    // Behavior never runs on a binding's first evaluation, so binding it
                    // straight to `popup` made the card appear in place instead of sliding in.
                    property real show: 0

                    width: column.width
                    // Collapses the gap as it leaves, so the stack closes up smoothly
                    height: Math.round(card.implicitHeight * show)
                    clip: true
                    Component.onCompleted: show = Qt.binding(() => modelData.popup ? 1 : 0)

                    Behavior on show {
                        Anim {
                            duration: slot.modelData.popup ? Appearance.animSlow : Appearance.animNormal
                            easing.bezierCurve: slot.modelData.popup ? Appearance.curveEmphasized : Appearance.curveStandard
                        }
                    }

                    NotifCard {
                        id: card

                        entry: slot.modelData
                        width: parent.width
                        // Slides in from the right edge it is anchored to, and leaves the
                        // same way. Deliberately no opacity fade: Hyprland's blur rule
                        // skips anything under 0.1 alpha, so a fading card crosses that
                        // threshold every frame and the blur region smears behind it.
                        x: Math.round((1 - slot.show) * width)
                    }
                }
            }
        }
    }
}
