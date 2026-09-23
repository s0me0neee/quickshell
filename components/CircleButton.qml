import QtQuick
import qs.common

// Round tinted bar button with a centered icon and an optional hover tooltip.
// Extra children (badges, rings) are drawn over the button.
MouseArea {
    id: root

    property string icon
    property real iconSize: 18
    property color fill: Theme.tonal
    property color iconColor: Theme.secondaryContainerText
    // Hand alignment for a glyph whose ink box doesn't sit where the eye wants it.
    // Positive x moves right, positive y moves down.
    property real iconNudgeX: 0
    property real iconNudgeY: 0
    property bool active: false
    property string tooltip
    default property alias extra: overlay.data

    implicitWidth: Appearance.circleSize
    implicitHeight: Appearance.circleSize
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.fill
        // Grows under the pointer (Clavis does this by changing the button's size;
        // scaling instead keeps the neighbours in a packed group still)
        scale: root.pressed ? 0.86 : root.containsMouse ? 1.12 : 1

        Behavior on color {
            CAnim {
                duration: Appearance.animNormal
            }
        }

        Behavior on scale {
            Anim {
                duration: Appearance.animNormal
                easing.bezierCurve: Appearance.curveExpressive
            }
        }

        StateLayer {
            radius: parent.radius
            tone: root.iconColor
            hovered: root.containsMouse
            pressed: root.pressed
            active: root.active
        }

        Icon {
            anchors.centerIn: parent
            text: root.icon
            size: root.iconSize
            color: root.iconColor
            nudgeX: root.iconNudgeX
            nudgeY: root.iconNudgeY
        }

        Item {
            id: overlay

            anchors.fill: parent
        }
    }

    Tooltip {
        target: root
        text: root.tooltip
        show: root.containsMouse && !root.pressed
    }
}
