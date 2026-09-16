import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.common
import qs.components

// Tray icons in their own glass group; hidden when no app has an icon.
Pill {
    id: root

    required property QtObject bar

    visible: SystemTray.items.values.length > 0
    padding: Appearance.groupPadding
    spacing: 2

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item

            required property SystemTrayItem modelData

            implicitWidth: Appearance.circleSize
            implicitHeight: Appearance.circleSize
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: event => {
                if (event.button === Qt.LeftButton && !modelData.onlyMenu)
                    modelData.activate();
                else if (event.button === Qt.MiddleButton)
                    modelData.secondaryActivate();
                else if (modelData.hasMenu)
                    menu.toggle();
            }
            onWheel: event => modelData.scroll(event.angleDelta.y, false)

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: item.containsMouse || menu.open ? Theme.tonal : "transparent"
                scale: item.pressed ? 0.86 : 1

                Behavior on color {
                    CAnim {
                        duration: Appearance.animFast
                    }
                }

                Behavior on scale {
                    Anim {
                        duration: Appearance.animNormal
                        easing.bezierCurve: Appearance.curveExpressive
                    }
                }
            }

            IconImage {
                anchors.centerIn: parent
                implicitSize: Appearance.iconSize
                asynchronous: true
                source: {
                    // Some apps send "name?path=/dir"; prefer the theme icon, else the file
                    const icon = item.modelData.icon;
                    if (!icon.includes("?path="))
                        return icon;
                    const [name, path] = icon.split("?path=");
                    const file = name.slice(name.lastIndexOf("/") + 1);
                    return Quickshell.iconPath(file, true) || `file://${path}/${file}`;
                }
            }

            Tooltip {
                target: item
                text: item.modelData.tooltipTitle || item.modelData.title || item.modelData.id
                show: item.containsMouse && !menu.open
            }

            TrayMenu {
                id: menu

                target: item
                bar: root.bar
                handle: item.modelData.menu
            }
        }
    }
}
