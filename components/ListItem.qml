import QtQuick
import QtQuick.Layouts
import qs.common

// A clickable row for popout lists: icon, label, optional subtitle and trailing content.
MouseArea {
    id: root

    property string icon
    property string label
    property string subtitle
    property int textFormat: Text.AutoText
    property bool highlighted
    default property alias trailing: trailingRow.data

    signal activated

    Layout.fillWidth: true
    implicitWidth: row.implicitWidth + Appearance.spacing * 2
    implicitHeight: subtitle ? 44 : 34
    hoverEnabled: true
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: activated()

    Rectangle {
        anchors.fill: parent
        radius: Appearance.radiusItem
        color: root.highlighted ? Qt.alpha(Theme.primary, root.containsMouse ? 0.22 : 0.14) : root.containsMouse ? Qt.alpha(Theme.surfaceText, 0.08) : "transparent"

        Behavior on color {
            CAnim {
                duration: Appearance.animFast
            }
        }
    }

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: Appearance.spacing
        anchors.rightMargin: Appearance.spacing
        spacing: Appearance.spacing + 2
        opacity: root.enabled ? 1 : 0.45

        Icon {
            visible: root.icon !== ""
            text: root.icon
            color: root.highlighted ? Theme.primary : Theme.surfaceVariantText
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.label
                textFormat: root.textFormat
                color: root.highlighted ? Theme.surfaceText : Theme.surfaceVariantText
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtitle !== ""
                text: root.subtitle
                textFormat: root.textFormat
                color: root.highlighted ? Theme.primary : Theme.textDim
                font.pixelSize: Appearance.fontSizeSmall
            }
        }

        RowLayout {
            id: trailingRow

            spacing: Appearance.spacingSmall
        }
    }
}
