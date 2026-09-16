pragma Singleton

import QtQuick
import Quickshell
import qs.common

// Session actions, in the same order and with the same keys and commands as the
// wlogout layout this replaces (~/.config/wlogout/layout).
Singleton {
    id: root

    property bool menuOpen: false

    readonly property list<var> actions: [
        {
            key: "l",
            label: "Lock",
            icon: Icons.lock,
            // Goes through logind, so hypridle's lock handling still applies
            command: ["loginctl", "lock-session"]
        },
        {
            key: "r",
            label: "Reboot",
            icon: Icons.restart,
            command: ["systemctl", "reboot"]
        },
        {
            key: "s",
            label: "Shutdown",
            icon: Icons.power,
            command: ["systemctl", "poweroff"]
        },
        {
            key: "e",
            label: "Logout",
            icon: Icons.logout,
            // $XDG_SESSION_ID needs a shell to expand it
            command: ["sh", "-c", "loginctl kill-session $XDG_SESSION_ID"]
        },
        {
            key: "u",
            label: "Suspend",
            icon: Icons.suspend,
            command: ["systemctl", "suspend"]
        },
        {
            key: "h",
            label: "Hibernate",
            icon: Icons.hibernate,
            command: ["systemctl", "hibernate"]
        }
    ]

    function openMenu(): void {
        menuOpen = true;
    }

    function close(): void {
        menuOpen = false;
    }

    function run(action: var): void {
        menuOpen = false;
        Quickshell.execDetached(action.command);
    }

    function runKey(key: string): bool {
        const action = actions.find(a => a.key === key);
        if (!action)
            return false;
        run(action);
        return true;
    }
}
