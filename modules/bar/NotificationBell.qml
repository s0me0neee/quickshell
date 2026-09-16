import QtQuick
import qs.common
import qs.components
import qs.services

// Left click: notification center. Right click: do not disturb. Badge shows the unread count.
CircleButton {
    id: root

    readonly property bool dnd: Swaync.state.startsWith("dnd")
    readonly property bool unread: Swaync.count > 0 && !dnd

    icon: Icons.notifications[Swaync.state] ?? Icons.notifications["none"]
    fill: unread ? Theme.accent : Theme.tonal
    iconColor: unread ? Theme.primaryContainerText : Theme.secondaryContainerText
    tooltip: dnd ? "Do not disturb" : unread ? `${Swaync.count} notification${Swaync.count === 1 ? "" : "s"}` : "No notifications"
    onClicked: mouse => mouse.button === Qt.RightButton ? Swaync.toggleDnd() : Swaync.toggleCenter()

    Rectangle {
        x: parent.width - width + 4
        y: -3
        width: Math.max(14, badgeText.implicitWidth + 6)
        height: 14
        radius: 7
        color: Theme.primary
        scale: root.unread ? 1 : 0

        Behavior on scale {
            Anim {
                duration: Appearance.animNormal
                easing.bezierCurve: Appearance.curveExpressive
            }
        }

        StyledText {
            id: badgeText

            anchors.centerIn: parent
            text: Swaync.count > 9 ? "9+" : Swaync.count
            color: Theme.primaryText
            font.pixelSize: 9
            font.weight: Font.Bold
        }
    }
}
