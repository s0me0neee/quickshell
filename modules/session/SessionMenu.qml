import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

// Full-screen session menu, built to the shape of the wlogout it replaces: the same
// six actions in the same 3x2 grid, the same keys (l r s e u h), the same rounded
// tiles whose icon swells on hover. Glass and wallpaper colors instead of wlogout's
// flat black, and Hyprland blurs everything behind it.
PanelWindow {
    id: root

    property real progress: Session.menuOpen ? 1 : 0
    // Keyboard selection; the pointer moves it too, so both stay in sync
    property int selected: 0

    function move(delta: int): void {
        const count = Session.actions.length;
        selected = (selected + delta + count) % count;
    }

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "qs-session"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Session.menuOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Behavior on progress {
        Anim {
            duration: Session.menuOpen ? Appearance.animSlow : Appearance.animNormal
            easing.bezierCurve: Session.menuOpen ? Appearance.curveEmphasized : Appearance.curveStandard
        }
    }

    // Dim over the blur
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.surface, 0.5)
        opacity: root.progress

        MouseArea {
            anchors.fill: parent
            onClicked: Session.close()
        }
    }

    FocusScope {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                Session.close();
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                Session.run(Session.actions[root.selected]);
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                root.move(1);
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
                root.move(-1);
            } else if (event.key === Qt.Key_Down) {
                root.move(3);
            } else if (event.key === Qt.Key_Up) {
                root.move(-3);
            } else if (!Session.runKey(event.text.toLowerCase())) {
                return;
            }
            event.accepted = true;
        }

        GridLayout {
            anchors.fill: parent
            anchors.margins: 20
            columns: 3
            columnSpacing: 20
            rowSpacing: 20
            opacity: root.progress
            scale: 0.96 + 0.04 * root.progress

            Repeater {
                model: Session.actions

                MouseArea {
                    id: tile

                    required property var modelData
                    required property int index
                    readonly property bool current: root.selected === index

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selected = index
                    onClicked: Session.run(modelData)

                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        color: tile.current ? Theme.accent : Theme.glass
                        border.width: 1
                        border.color: tile.current ? Qt.alpha(Theme.primary, 0.5) : Theme.glassEdge
                        scale: tile.pressed ? 0.98 : 1

                        Behavior on color {
                            CAnim {
                                duration: Appearance.animFast
                            }
                        }

                        Behavior on scale {
                            Anim {
                                duration: Appearance.animFast
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: Appearance.spacingLarge

                            Icon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.modelData.icon
                                // wlogout grew the icon from 20% to 30% on hover
                                size: Math.round(Math.min(tile.width, tile.height) * (tile.current ? 0.3 : 0.2))
                                color: tile.current ? Theme.primaryContainerText : Theme.surfaceText

                                Behavior on size {
                                    Anim {
                                        duration: Appearance.animNormal
                                        easing.bezierCurve: Appearance.curveExpressive
                                    }
                                }
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: tile.modelData.label
                                color: tile.current ? Theme.primaryContainerText : Theme.surfaceText
                                font.pixelSize: 20
                            }
                        }

                        // The key that triggers this tile, like wlogout's bindings
                        StyledText {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: 18
                            text: tile.modelData.key.toUpperCase()
                            color: Qt.alpha(tile.current ? Theme.primaryContainerText : Theme.surfaceText, 0.45)
                            font.pixelSize: Appearance.fontSizeSmall
                            font.weight: Font.Bold
                        }
                    }
                }
            }
        }
    }
}
