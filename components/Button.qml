import QtQuick
import qs.common

// Compact text button. `filled` uses the accent; otherwise it is a soft tonal button.
MouseArea {
    id: root

    property string text
    property bool filled: false
    property color tone: Theme.primary

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 30
    hoverEnabled: true
    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    opacity: enabled ? 1 : 0.45

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.filled ? Qt.lighter(root.tone, root.containsMouse ? 1.1 : 1) : Qt.alpha(root.tone, root.containsMouse ? 0.24 : 0.14)
        scale: root.pressed ? 0.95 : 1

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
    }

    StyledText {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: root.filled ? Theme.primaryText : root.tone
        font.pixelSize: Appearance.fontSizeSmall + 1
        font.weight: Font.DemiBold
    }
}
