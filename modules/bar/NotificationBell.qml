import QtQuick
import qs.common
import qs.components
import qs.services

// Left click: the notification list. Right click: do not disturb.
// The badge counts what the shell is holding.
CircleButton {
    id: root

    required property QtObject bar

    readonly property bool dnd: Notifs.dnd
    readonly property bool unread: Notifs.count > 0 && !dnd

    icon: {
        if (dnd)
            return Notifs.count > 0 ? Icons.notifications["dnd-notification"] : Icons.notifications["dnd-none"];
        return Notifs.count > 0 ? Icons.notifications["notification"] : Icons.notifications["none"];
    }
    fill: unread ? Theme.accent : Theme.tonal
    iconColor: unread ? Theme.primaryContainerText : Theme.secondaryContainerText
    active: center.open
    tooltip: center.open ? "" : dnd ? "Do not disturb" : unread ? `${Notifs.count} notification${Notifs.count === 1 ? "" : "s"}` : "No notifications"
    onClicked: mouse => mouse.button === Qt.RightButton ? Notifs.toggleDnd() : center.toggle()

    NotifCenter {
        id: center

        target: root
        bar: root.bar
    }

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
            text: Notifs.count > 9 ? "9+" : Notifs.count
            color: Theme.primaryText
            font.pixelSize: 9
            font.weight: Font.Bold
        }
    }
}
