pragma Singleton

import QtQuick
import Quickshell
import Preview

QtObject {
    id: root

    property var itemList: []
    readonly property var items: ({
            values: itemList
        })

    readonly property QsMenuHandle networkMenu: QsMenuHandle {
        QsMenuEntry {
            text: "Enable _Networking"
            buttonType: QsMenuButtonType.CheckBox
            checkState: Qt.Checked
        }
        QsMenuEntry {
            text: "Enable Wi-Fi"
            buttonType: QsMenuButtonType.CheckBox
            checkState: Qt.Checked
        }
        QsMenuEntry {
            isSeparator: true
        }
        QsMenuEntry {
            text: "Connections"

            QsMenuEntry {
                text: "Wired connection 1"
            }
            QsMenuEntry {
                text: "home-5g"
            }
        }
        QsMenuEntry {
            text: "Edit Connections…"
        }
        QsMenuEntry {
            text: "About"
            enabled: false
        }
    }

    readonly property QsMenuHandle plainMenu: QsMenuHandle {
        QsMenuEntry {
            text: "Open"
        }
        QsMenuEntry {
            isSeparator: true
        }
        QsMenuEntry {
            text: "Quit"
        }
    }

    readonly property Component itemComponent: Component {
        SystemTrayItem {}
    }

    Component.onCompleted: {
        if (!Preview.scene("tray"))
            return;
        const spec = [
            {
                id: "nm-applet",
                title: "Network Manager",
                tooltipTitle: "Wired connection 1",
                icon: `${Preview.icons}/tray-network.png`,
                menu: networkMenu
            },
            {
                id: "blueman",
                title: "Bluetooth",
                tooltipTitle: "Bluetooth: on",
                icon: `${Preview.icons}/tray-bluetooth.png`,
                menu: plainMenu
            },
            {
                id: "fcitx",
                title: "Fcitx 5",
                tooltipTitle: "Input method",
                icon: `${Preview.icons}/tray-input.png`,
                menu: plainMenu
            }
        ];
        itemList = spec.map(entry => itemComponent.createObject(root, entry));
    }
}
