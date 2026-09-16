pragma Singleton

import QtQuick
import Preview

QtObject {
    id: root

    readonly property list<ShellScreen> screens: [
        ShellScreen {
            name: "PREVIEW-1"
            model: "Preview"
            width: Preview.screenWidth
            height: Preview.screenHeight
        }
    ]

    // Theme.qml reads $HOME to find the palette matugen writes
    function env(name: string): string {
        return name === "HOME" ? Preview.home : "";
    }

    function execDetached(command: var): void {
        console.log("[preview] execDetached:", JSON.stringify(command));
    }

    // No XDG icon themes here, so a bare theme name resolves to nothing. Anything that
    // is already a path or a URL — which is all the mock services hand out — passes through.
    function iconPath(name: string, check: bool): string {
        return /^(file:|\/)/.test(name) ? name : "";
    }
}
