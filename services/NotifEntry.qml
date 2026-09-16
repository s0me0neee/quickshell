pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications
import qs.services

// One notification, copied out of the server's object so it outlives the app that
// sent it: the popup goes away, the entry in the list stays. While the sender is
// still around, changes are mirrored back in.
QtObject {
    id: root

    property Notification notification

    // Showing as a popup right now. Goes false on timeout or dismissal; the entry
    // stays in the list either way.
    property bool popup: true
    property bool closed: false

    property string summary: ""
    property string body: ""
    property string appName: ""
    property string appIcon: ""
    property string image: ""
    property int urgency: NotificationUrgency.Normal
    property real expireTimeout: -1
    property list<var> actions: []

    readonly property date time: new Date()
    readonly property bool critical: urgency === NotificationUrgency.Critical

    // Same timings as the swaync setup this replaces
    readonly property int timeout: expireTimeout > 0 ? expireTimeout : critical ? 6000 : urgency === NotificationUrgency.Low ? 2000 : 4000

    readonly property Timer expiry: Timer {
        running: root.popup
        interval: root.timeout
        onTriggered: root.popup = false
    }

    // The sender can edit a notification in place (progress bars, download counts)
    readonly property Connections live: Connections {
        target: root.notification

        function onClosed(): void {
            root.close();
        }

        function onSummaryChanged(): void {
            root.summary = root.notification.summary;
        }

        function onBodyChanged(): void {
            root.body = root.notification.body;
        }

        function onImageChanged(): void {
            root.image = root.notification.image;
        }

        function onUrgencyChanged(): void {
            root.urgency = root.notification.urgency;
        }

        function onActionsChanged(): void {
            root.actions = root.readActions();
        }
    }

    // Actions are wrapped in plain objects: the server object can go away while the
    // entry is still listed in history
    function readActions(): list<var> {
        return notification?.actions.map(a => ({
                    identifier: a.identifier,
                    text: a.text,
                    invoke: () => a.invoke()
                })) ?? [];
    }

    // Stop showing the popup, keep the entry
    function dismiss(): void {
        popup = false;
    }

    // Drop it entirely, and tell the sender
    function close(): void {
        if (closed)
            return;
        closed = true;
        popup = false;
        Notifs.forget(root);
        notification?.dismiss();
        destroy();
    }

    Component.onCompleted: {
        if (!notification)
            return;
        summary = notification.summary;
        body = notification.body;
        appName = notification.appName;
        appIcon = notification.appIcon;
        image = notification.image;
        urgency = notification.urgency;
        expireTimeout = notification.expireTimeout;
        actions = readActions();
    }
}
