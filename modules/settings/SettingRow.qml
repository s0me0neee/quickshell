import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

// One setting: what it is on the left, what it does on the right.
//
// The control goes in the default slot, so a row can hold a toggle, a segmented
// choice or a slider without this knowing which.
RowLayout {
    id: root

    property string label
    property string description
    default property alias control: trailing.data

    Layout.fillWidth: true
    spacing: Appearance.spacingLarge

    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Appearance.spacingSmall
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            text: root.label
            elide: Text.ElideRight
        }

        // Why you would touch it, for the ones where that isn't obvious
        StyledText {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.description
            color: Theme.textDim
            wrapMode: Text.Wrap
            font.pixelSize: Appearance.fontSizeSmall - 1
        }
    }

    RowLayout {
        id: trailing

        Layout.alignment: Qt.AlignVCenter
        spacing: Appearance.spacing
    }
}
