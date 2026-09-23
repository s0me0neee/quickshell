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
        color: root.filled ? root.tone : Qt.alpha(root.tone, 0.14)
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

        StateLayer {
            radius: parent.radius
            tone: root.filled ? Theme.primaryText : root.tone
            hovered: root.containsMouse
            pressed: root.pressed
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
