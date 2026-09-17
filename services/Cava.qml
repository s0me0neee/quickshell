pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Spectrum levels from cava.
//
// Caelestia links libcava into a C++ plugin; this config builds nothing, so it runs the
// cava binary and reads the raw levels it prints. Same numbers, no build step.
//
// This is the one thing in the shell that redraws continuously, so it is wired to stay
// off by default: cava is only launched while something has called watch(), and the
// media card only does that while it is on screen *and* audio is playing. Closing the
// card kills the process outright rather than idling it.
Singleton {
    id: root

    readonly property int bars: Settings.data.visualiserBars
    readonly property int framerate: Settings.data.visualiserFramerate

    // Written rather than shipped: the bar count and frame rate are settings, and a file
    // in the repo would show up as a change every time one of them moved. Generated
    // state belongs next to colors.json
    readonly property string configPath: `${Quickshell.env("HOME")}/.local/state/quickshell/cava.conf`
    property bool configReady: false

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

    // ascii_max_range 100, ';' between bars, newline between frames
    function configText(): string {
        return `[general]
mode = normal
framerate = ${framerate}
bars = ${bars}
autosens = 1

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
frame_delimiter = 10

[smoothing]
noise_reduction = 40
`;
    }

    // Dropping configReady stops cava, and raising it starts the new one, so changing
    // the bar count in the settings restarts it with the new config rather than
    // leaving the old process running against a file it has already read
    function writeConfig(): void {
        configReady = false;
        config.setText(configText());
    }

    Component.onCompleted: writeConfig()
    onBarsChanged: writeConfig()
    onFramerateChanged: writeConfig()

    FileView {
        id: config

        path: root.configPath
        onSaved: root.configReady = true
        onSaveFailed: error => console.warn(`Cava: could not write ${root.configPath}: ${error}`)
    }

    Process {
        id: proc

        running: root.readers > 0 && root.configReady && Settings.data.visualiser
        command: ["cava", "-p", root.configPath]

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
