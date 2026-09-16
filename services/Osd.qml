pragma Singleton

import QtQuick
import Quickshell
import qs.common

// What the island shows instead of the track for a moment after the volume or
// brightness changes.
//
// Driven by the values themselves rather than by the key binds, so it covers every
// source at once: the laptop keys, the bar's own scroll wheels, wpctl from a script,
// hypridle dimming the screen. Nothing here needs a Hyprland bind to exist.
Singleton {
    id: root

    // "", "volume", "mic" or "brightness". The island maps it to a glyph and a value.
    property string kind: ""
    readonly property bool active: kind !== ""

    // Every binding below evaluates once as the services fill in, and Pipewire takes a
    // moment to hand over a default sink. Without this the shell would greet you with
    // an OSD every time it reloads.
    property bool ready: false

    // The panel that owns this value is already showing a slider for it, and the island
    // sits right above it — two of the same reading, one of them a frame behind
    readonly property bool suppressed: !ready || PopoutState.current !== null

    function show(what: string): void {
        if (suppressed)
            return;
        kind = what;
        hide.restart();
    }

    Timer {
        id: hide

        interval: 1600
        onTriggered: root.kind = ""
    }

    Timer {
        interval: 1200
        running: true
        onTriggered: root.ready = true
    }

    Connections {
        target: Audio

        function onVolumeChanged(): void {
            root.show("volume");
        }

        function onMutedChanged(): void {
            root.show("volume");
        }

        function onMicVolumeChanged(): void {
            root.show("mic");
        }

        function onMicMutedChanged(): void {
            root.show("mic");
        }
    }

    Connections {
        target: Brightness

        function onBrightnessChanged(): void {
            root.show("brightness");
        }
    }
}
