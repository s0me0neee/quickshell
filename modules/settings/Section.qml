import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

// A titled card. Every settings page is a stack of these.
ColumnLayout {
    id: root

    property string title
    default property alias rows: card.data

    Layout.fillWidth: true
    spacing: Appearance.spacingSmall

    StyledText {
        Layout.leftMargin: Appearance.spacingSmall
        text: root.title
        color: Theme.surfaceVariantText
        font.pixelSize: Appearance.fontSizeSmall
        font.weight: Font.DemiBold
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: card.implicitHeight + Appearance.spacing * 2
        radius: Appearance.radiusItem + 4
        color: Qt.alpha(Theme.surfaceContainer, 0.55)

        ColumnLayout {
            id: card

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Appearance.spacing
            spacing: Appearance.spacingSmall
        }
    }
}
