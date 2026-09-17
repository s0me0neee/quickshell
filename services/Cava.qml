pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Spectrum levels from cava.
//
// Caelestia links libcava into a C++ plugin; this config builds nothing, so it runs the
// cava binary instead and reads the raw levels it prints. Same numbers, no build step.
//
// This is the one thing in the shell that redraws continuously, so it is wired to stay
// off by default: cava is only launched while something has called watch(), and the
// media card only does that while it is on screen *and* audio is playing. Closing the
// card kills the process outright rather than idling it.
Singleton {
    id: root

    // Must match `bars` in assets/cava.conf
    readonly property int bars: 28
    readonly property string config: `${Quickshell.env("HOME")}/.config/quickshell/assets/cava.conf`

    // 0-1 per bar. Zero-filled up front so anything drawing them has a shape to bind to
    // before the first frame arrives
    property var values: new Array(bars).fill(0)

    // Counted rather than a flag: two cards on two monitors can want it at once
    property int readers: 0
    readonly property bool running: proc.running

    function watch(): void {
        readers += 1;
    }

    function unwatch(): void {
        readers = Math.max(0, readers - 1);
    }

    Process {
        id: proc

        running: root.readers > 0
        command: ["cava", "-p", root.config]

        // Falling back to silence rather than leaving the last frame frozen on screen
        onRunningChanged: {
            if (!running)
                root.values = new Array(root.bars).fill(0);
        }

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: line => {
                const parts = line.split(";");
                // cava ends every frame with a trailing delimiter, so the last split is
                // an empty string
                const levels = [];
                for (let i = 0; i < parts.length; i++) {
                    if (parts[i] === "")
                        continue;
                    levels.push(Math.min(1, parseInt(parts[i]) / 100));
                }
                if (levels.length > 0)
                    root.values = levels;
            }
        }
    }
}
