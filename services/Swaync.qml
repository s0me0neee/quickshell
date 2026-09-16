pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Temporary bridge to swaync. Phase 2 replaces this with a notification server in the shell.
Singleton {
    id: root

    // swaync's state name, e.g. "none", "notification", "dnd-none"
    property string state: "none"
    property int count: 0

    function toggleCenter(): void {
        Quickshell.execDetached(["swaync-client", "-t", "-sw"]);
    }

    function toggleDnd(): void {
        Quickshell.execDetached(["swaync-client", "-d", "-sw"]);
    }

    // -swb subscribes: swaync pushes a JSON line on every change, no polling
    Process {
        running: true
        command: ["swaync-client", "-swb"]
        stdout: SplitParser {
            onRead: line => {
                try {
                    const data = JSON.parse(line);
                    root.state = data.alt ?? "none";
                    root.count = parseInt(data.text) || 0;
                } catch (e) {}
            }
        }
    }
}
