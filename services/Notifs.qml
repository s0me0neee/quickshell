pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications

// The notification daemon. Replaces swaync: this owns org.freedesktop.Notifications,
// so only one of the two can run at a time.
Singleton {
    id: root

    // Newest first
    property list<NotifEntry> list: []
    readonly property list<NotifEntry> popups: list.filter(n => n.popup)
    readonly property int count: list.length
    property alias dnd: props.dnd

    // Popups are held back while do-not-disturb is on, or while something is
    // fullscreen on the focused monitor — a video or a game shouldn't be covered.
    // They still land in the list, so nothing is lost.
    readonly property bool fullscreen: Hyprland.focusedMonitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false

    function shouldPopUp(): bool {
        return !dnd && !fullscreen;
    }

    function toggleDnd(): void {
        props.dnd = !props.dnd;
    }

    // Remove one entry from the list. Called by the entry as it closes itself.
    function forget(entry: NotifEntry): void {
        list = list.filter(n => n !== entry);
    }

    function clearAll(): void {
        for (const entry of list.slice())
            entry.close();
    }

    // Stop every popup without clearing the list
    function dismissPopups(): void {
        for (const entry of popups)
            entry.dismiss();
    }

    PersistentProperties {
        id: props

        property bool dnd: false

        reloadableId: "notifs"
    }

    NotificationServer {
        id: server

        // Editing the config shouldn't throw away what you haven't read yet
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            notification.tracked = true;

            const entry = entryComponent.createObject(root, {
                notification,
                popup: root.shouldPopUp()
            });
            root.list = [entry, ...root.list];
        }
    }

    Component {
        id: entryComponent

        NotifEntry {}
    }

    // A reload hands the new server the notifications the old one was holding, but
    // the list itself starts empty: adopt them so nothing disappears mid-session.
    Component.onCompleted: {
        const tracked = server.trackedNotifications.values;
        if (tracked.length === 0)
            return;
        root.list = tracked.map(notification => entryComponent.createObject(root, {
                    notification,
                    popup: false
                })).reverse();
    }

    IpcHandler {
        target: "notifs"

        function clear(): void {
            root.clearAll();
        }

        function toggleDnd(): bool {
            root.toggleDnd();
            return root.dnd;
        }

        function count(): int {
            return root.count;
        }
    }
}
