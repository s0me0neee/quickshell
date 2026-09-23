pragma Singleton

import QtQuick
import Quickshell
import qs.common
import qs.services

// What the island shows instead of the track for a moment after the volume or
// brightness changes.
//
// Driven by the values themselves rather than by the key binds, so it covers every
// source at once: the laptop keys, the bar's own scroll wheels, wpctl from a script,
// hypridle dimming the screen. Nothing here needs a Hyprland bind to exist.
Singleton {
    id: root

    // "", "volume", "mic" or "brightness".
    property string kind: ""
    readonly property bool active: kind !== ""

    // What the current kind reads, as data. Two surfaces draw this now — the island and
    // the fullscreen overlay — so it lives here rather than in either of them.
    //
    // The *eased* version of `value` belongs to each surface, not here: easing is
    // motion, and a service that imported qs.components to get `Anim` would have a
    // singleton depending on the UI layer.
    readonly property bool muted: (kind === "volume" && Audio.muted) || (kind === "mic" && Audio.micMuted)

    readonly property real value: {
        if (kind === "mic")
            return Audio.micMuted ? 0 : Audio.micVolume;
        if (kind === "brightness")
            return Brightness.brightness;
        return Audio.muted ? 0 : Audio.volume;
    }

    readonly property string icon: {
        if (kind === "mic")
            return Audio.micMuted ? Icons.micMuted : Icons.mic;
        if (kind === "brightness")
            return Icons.pick(Icons.brightness, Brightness.brightness);
        return Audio.muted ? Icons.volumeMuted : Icons.pick(Icons.volume, Audio.volume);
    }

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

    // A fullscreen window covers the bar, so the island's morph can't be seen. The OSD
    // then gets its own surface on the overlay layer instead — see modules/osd/.
    readonly property bool overlay: active && Notifs.fullscreen

    // Held a little past `overlay` so the surface can finish sliding out before
    // shell.qml drops it. Counted here rather than off the window's own progress: an
    // active that depends on the item it creates never settles.
    property bool overlayLive: false

    onOverlayChanged: {
        if (overlay) {
            overlayLinger.stop();
            overlayLive = true;
        } else {
            overlayLinger.restart();
        }
    }

    Timer {
        id: overlayLinger

        interval: Appearance.animNormal + 150
        onTriggered: root.overlayLive = false
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
