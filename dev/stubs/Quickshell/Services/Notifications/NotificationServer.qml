import QtQuick
import Preview

// Sends a few fake notifications on a delay so the popup stack can be watched arriving
// and leaving, which is the only way to judge its timings.
QtObject {
    id: root

    property bool keepOnReload: false
    property bool actionsSupported: false
    property bool bodySupported: false
    property bool bodyMarkupSupported: false
    property bool bodyImagesSupported: false
    property bool imageSupported: false
    property bool persistenceSupported: false

    readonly property var trackedNotifications: ({
            values: []
        })

    signal notification(var notification)

    readonly property var fakes: [
        {
            appName: "Signal",
            summary: "Rin",
            body: "the bar looks good with the new palette",
            icon: "chat",
            urgency: NotificationUrgency.Normal,
            actions: ["Reply", "Mark read"]
        },
        {
            appName: "System",
            summary: "Update available",
            body: "142 packages can be upgraded, including linux-firmware and mesa.",
            icon: "update",
            urgency: NotificationUrgency.Low,
            actions: []
        },
        {
            appName: "Battery",
            summary: "Battery low",
            body: "9% remaining. Plug in soon.",
            icon: "battery",
            urgency: NotificationUrgency.Critical,
            actions: ["Suspend"]
        },
        // Three more from an app that has already sent one, so the list has a group to
        // fold as well as singles to leave alone
        {
            appName: "Signal",
            summary: "Mira",
            body: "did the workspace capsule land?",
            icon: "chat",
            urgency: NotificationUrgency.Normal,
            actions: ["Reply"]
        },
        {
            appName: "Signal",
            summary: "Rin",
            body: "sending the screenshot now",
            icon: "chat",
            urgency: NotificationUrgency.Normal,
            actions: ["Reply", "Mark read"]
        },
        {
            appName: "Signal",
            summary: "Dev channel",
            body: "4 new messages",
            icon: "chat",
            urgency: NotificationUrgency.Low,
            actions: []
        }
    ]

    readonly property Component notificationComponent: Component {
        Notification {}
    }

    function send(spec: var): void {
        root.notification(notificationComponent.createObject(root, {
                    appName: spec.appName,
                    summary: spec.summary,
                    body: spec.body,
                    appIcon: `${Preview.icons}/notif-${spec.icon}.png`,
                    urgency: spec.urgency,
                    // Long enough to look at; the shell's own timings still decide
                    expireTimeout: 12000,
                    actions: spec.actions.map(text => ({
                                identifier: text.toLowerCase(),
                                text,
                                invoke: () => console.log("[preview] action:", text)
                            }))
                }));
    }

    property int sent: 0

    readonly property Timer sender: Timer {
        running: Preview.scene("notifs") && root.sent < root.fakes.length
        repeat: true
        interval: root.sent === 0 ? 900 : 1600
        onTriggered: {
            root.send(root.fakes[root.sent]);
            root.sent++;
        }
    }
}
