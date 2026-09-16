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
        property list<NotifEntry> shown: []

        function sync(): void {
            const live = Notifs.popups;
            const kept = shown.filter(n => live.includes(n) || !n.closed);
            for (const entry of live)
                if (!kept.includes(entry))
                    kept.unshift(entry);
            shown = kept;
        }

        function drop(entry: NotifEntry): void {
            shown = shown.filter(n => n !== entry && !n.closed);
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
        implicitHeight: Math.max(1, column.implicitHeight)

        WlrLayershell.namespace: "qs-notifications"
        WlrLayershell.layer: WlrLayer.Top

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

            Repeater {
                model: win.shown

                Item {
                    id: slot

                    required property NotifEntry modelData

                    // 1 while the popup is up, 0 once it has left
                    property real show: modelData.popup ? 1 : 0

                    width: column.width
                    // Collapses the gap as it leaves, so the stack closes up smoothly
                    height: Math.round(card.implicitHeight * show)
                    clip: true

                    Behavior on show {
                        Anim {
                            duration: slot.modelData.popup ? Appearance.animSlow : Appearance.animNormal
                            easing.bezierCurve: slot.modelData.popup ? Appearance.curveEmphasized : Appearance.curveStandard
                            onFinished: {
                                if (slot.show === 0)
                                    win.drop(slot.modelData);
                            }
                        }
                    }

                    NotifCard {
                        id: card

                        entry: slot.modelData
                        width: parent.width
                        // Slides in from the right edge it is anchored to
                        x: Math.round((1 - slot.show) * width)
                        opacity: slot.show
                    }
                }
            }
        }
    }
}
