pragma Singleton

import QtQuick
import Preview

// Fake compositor state. `dispatch` really does move the active workspace, so clicking
// and scrolling the workspace dots drives the same animation it drives on Hyprland.
QtObject {
    id: root

    // Windows per workspace, which is what decides a filled dot from an empty one
    readonly property var windowCounts: [2, 3, 0, 1, 0, 4, 0]
    readonly property int urgentId: 6

    property int activeId: 2

    property var workspaceList: []
    readonly property var workspaces: ({
            values: workspaceList
        })

    readonly property HyprlandMonitor focusedMonitor: HyprlandMonitor {
        name: "PREVIEW-1"
        activeWorkspace: root.workspaceById(root.activeId)
    }

    function workspaceById(id: int): var {
        return workspaceList.find(w => w.id === id) ?? null;
    }

    function monitorFor(screen: var): var {
        return focusedMonitor;
    }

    function dispatch(command: string): void {
        const match = /^workspace\s+(\S+)$/.exec(command);
        if (!match) {
            console.log("[preview] dispatch:", command);
            return;
        }
        const target = match[1];
        if (target === "e+1")
            activeId = activeId % workspaceList.length + 1;
        else if (target === "e-1")
            activeId = (activeId - 2 + workspaceList.length) % workspaceList.length + 1;
        else
            activeId = parseInt(target);
    }

    readonly property Component workspaceComponent: Component {
        HyprlandWorkspace {}
    }

    Component.onCompleted: {
        const made = [];
        for (let i = 0; i < windowCounts.length; i++)
            made.push(workspaceComponent.createObject(root, {
                        id: i + 1,
                        name: `${i + 1}`,
                        monitor: focusedMonitor,
                        windows: windowCounts[i],
                        urgent: i + 1 === urgentId
                    }));
        workspaceList = made;
    }
}
