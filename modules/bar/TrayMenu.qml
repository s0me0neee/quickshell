import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.components

// Tray app menu drawn in the shell's own style. Submenus open in place with a back row.
Popout {
    id: root

    required property QsMenuHandle handle
    property var path: []
    readonly property QsMenuHandle current: path.length > 0 ? path[path.length - 1] : handle

    // Connections rather than a handler on the root: a handler here would replace
    // Popout's own onOpenChanged, which is what registers this as the open popout and
    // closes any other one
    Connections {
        target: root

        function onOpenChanged(): void {
            if (!root.open)
                root.path = [];
        }
    }

    QsMenuOpener {
        id: opener

        menu: root.current
    }

    MenuRow {
        visible: root.path.length > 0
        icon: Icons.back
        label: "Back"
        onActivated: root.path = root.path.slice(0, -1)
    }

    Repeater {
        model: opener.children

        Item {
            id: entry

            required property QsMenuEntry modelData

            Layout.fillWidth: true
            implicitWidth: row.implicitWidth
            implicitHeight: modelData.isSeparator ? 9 : row.implicitHeight

            Rectangle {
                visible: entry.modelData.isSeparator
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 1
                color: Qt.alpha(Theme.outlineVariant, 0.6)
            }

            MenuRow {
                id: row

                visible: !entry.modelData.isSeparator
                width: parent.width
                enabled: entry.modelData.enabled
                label: entry.modelData.text.replace(/_(?!_)/g, "")
                image: entry.modelData.icon
                icon: {
                    const e = entry.modelData;
                    if (e.buttonType === QsMenuButtonType.CheckBox)
                        return e.checkState === Qt.Checked ? Icons.checkOn : Icons.checkOff;
                    if (e.buttonType === QsMenuButtonType.RadioButton)
                        return e.checkState === Qt.Checked ? Icons.radioOn : Icons.radioOff;
                    return "";
                }
                submenu: entry.modelData.hasChildren
                onActivated: {
                    if (entry.modelData.hasChildren) {
                        root.path = [...root.path, entry.modelData];
                    } else {
                        entry.modelData.triggered();
                        root.open = false;
                    }
                }
            }
        }
    }

    component MenuRow: MouseArea {
        id: menuRow

        property string label
        property string icon
        property string image
        property bool submenu

        signal activated

        Layout.fillWidth: true
        implicitWidth: Math.max(200, content.implicitWidth + Appearance.spacing * 2)
        implicitHeight: 30
        hoverEnabled: true
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: activated()

        Rectangle {
            anchors.fill: parent
            radius: Appearance.radiusItem
            color: menuRow.containsMouse && menuRow.enabled ? Qt.alpha(Theme.surfaceText, 0.1) : "transparent"
        }

        RowLayout {
            id: content

            anchors.fill: parent
            anchors.leftMargin: Appearance.spacing
            anchors.rightMargin: Appearance.spacing
            spacing: Appearance.spacing
            opacity: menuRow.enabled ? 1 : 0.4

            Icon {
                visible: menuRow.icon !== ""
                text: menuRow.icon
                color: Theme.primary
            }

            IconImage {
                visible: menuRow.image !== ""
                source: menuRow.image
                implicitSize: Appearance.themeIconSizeSmall
            }

            StyledText {
                Layout.fillWidth: true
                text: menuRow.label
            }

            Icon {
                visible: menuRow.submenu
                text: Icons.chevronRight
                color: Theme.surfaceVariantText
            }
        }
    }
}
