import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services

// Tray icons in their own glass group; hidden when no app has an icon.
Pill {
    id: root

    required property QtObject bar

    visible: Settings.data.showTray && SystemTray.items.values.length > 0
    padding: Appearance.groupPadding
    spacing: 2

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: item

            required property SystemTrayItem modelData

            property bool menuOpen: false
            readonly property bool menuLive: menuOpen || menuLinger.running

            onMenuOpenChanged: {
                if (menuOpen)
                    menuLinger.stop();
                else
                    menuLinger.restart();
                if (menuLoader.item)
                    menuLoader.item.open = item.menuOpen;
            }

            Timer {
                id: menuLinger

                interval: Appearance.animNormal + 80
            }

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
                    item.menuOpen = !item.menuOpen;
            }
            onWheel: event => modelData.scroll(event.angleDelta.y, false)

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: item.containsMouse || item.menuOpen ? Theme.tonal : "transparent"
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
                implicitSize: Appearance.themeIconSize
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
                show: item.containsMouse && !item.menuOpen
            }

            LazyLoader {
                id: menuLoader

                active: item.menuLive

                TrayMenu {
                    id: menu

                    target: item
                    bar: root.bar
                    handle: item.modelData.menu
                }
            }

            Connections {
                target: menuLoader

                // Created a moment after `active` flips; open it then, animation and all
                function onItemChanged(): void {
                    if (menuLoader.item)
                        menuLoader.item.open = item.menuOpen;
                }
            }

            Connections {
                target: menuLoader.item

                function onOpenChanged(): void {
                    if (menuLoader.item && item.menuOpen !== menuLoader.item.open)
                        item.menuOpen = menuLoader.item.open;
                }
            }
        }
    }
}
