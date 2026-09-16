import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.modules.notifications
import qs.services

// The notification list, hanging under the bell. Everything the shell has received
// is here, newest first, whether or not its popup was shown.
Popout {
    id: root

    // Which apps are unfolded, keyed by name so the state survives the groups array
    // being rebuilt every time a notification arrives or is dismissed
    property var expandedApps: ({})

    function toggleApp(app: string): void {
        const next = Object.assign({}, expandedApps);
        next[app] = !next[app];
        expandedApps = next;
    }

    contentWidth: 400

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing

        StyledText {
            Layout.fillWidth: true
            text: Notifs.count === 0 ? "Notifications" : `Notifications · ${Notifs.count}`
            font.weight: Font.Bold
        }

        CircleButton {
            icon: Notifs.dnd ? Icons.notifications["dnd-none"] : Icons.notifications["none"]
            iconSize: 14
            fill: Notifs.dnd ? Theme.accent : Theme.tonal
            iconColor: Notifs.dnd ? Theme.primaryContainerText : Theme.secondaryContainerText
            tooltip: Notifs.dnd ? "Do not disturb is on" : "Do not disturb"
            onClicked: Notifs.toggleDnd()
        }

        CircleButton {
            icon: Icons.clearAll
            iconSize: 14
            enabled: Notifs.count > 0
            opacity: enabled ? 1 : 0.4
            tooltip: "Clear all"
            onClicked: Notifs.clearAll()
        }
    }

    Divider {}

    StyledText {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing
        Layout.bottomMargin: Appearance.spacing
        visible: Notifs.count === 0
        text: "Nothing here"
        color: Theme.textDim
        horizontalAlignment: Text.AlignHCenter
    }

    ListView {
        Layout.fillWidth: true
        // Grows with the list, then scrolls
        Layout.preferredHeight: Math.min(contentHeight, 460)
        visible: Notifs.count > 0
        spacing: Appearance.spacing
        clip: true
        model: Notifs.groups

        delegate: NotifGroup {
            required property var modelData

            app: modelData.app
            entries: modelData.entries
            expanded: root.expandedApps[modelData.app] ?? false
            width: ListView.view.width
            height: implicitHeight
            onToggled: root.toggleApp(modelData.app)
        }
    }
}
