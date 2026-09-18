import QtQuick
import Quickshell
import qs.common
import qs.components
import qs.services

// Left click: the notification list. Right click: do not disturb.
// The badge counts what the shell is holding.
CircleButton {
    id: root

    required property QtObject bar

    property bool centerOpen: false
    readonly property bool centerLive: centerOpen || centerLinger.running

    onCenterOpenChanged: {
        if (centerOpen)
            centerLinger.stop();
        else
            centerLinger.restart();
        if (centerLoader.item)
            centerLoader.item.open = root.centerOpen;
    }

    Timer {
        id: centerLinger

        interval: Appearance.animNormal + 80
    }

    readonly property bool dnd: Notifs.dnd
    readonly property bool unread: Notifs.count > 0 && !dnd

    icon: {
        if (dnd)
            return Notifs.count > 0 ? Icons.notifications["dnd-notification"] : Icons.notifications["dnd-none"];
        return Notifs.count > 0 ? Icons.notifications["notification"] : Icons.notifications["none"];
    }
    fill: unread ? Theme.accent : Theme.tonal
    iconColor: unread ? Theme.primaryContainerText : Theme.secondaryContainerText
    active: root.centerOpen
    tooltip: root.centerOpen ? "" : dnd ? "Do not disturb" : unread ? `${Notifs.count} notification${Notifs.count === 1 ? "" : "s"}` : "No notifications"
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            Notifs.toggleDnd();
        else
            root.centerOpen = !root.centerOpen;
    }

    LazyLoader {
        id: centerLoader

        active: root.centerLive

        NotifCenter {
            id: center

            target: root
            bar: root.bar
        }
    }

    Connections {
        target: centerLoader

        // Created a moment after `active` flips; open it then, animation and all
        function onItemChanged(): void {
            if (centerLoader.item)
                centerLoader.item.open = root.centerOpen;
        }
    }

    Connections {
        target: centerLoader.item

        function onOpenChanged(): void {
            if (centerLoader.item && root.centerOpen !== centerLoader.item.open)
                root.centerOpen = centerLoader.item.open;
        }
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
