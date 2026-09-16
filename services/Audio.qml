pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property bool headphones: /bluez|headphone|headset/i.test(sink?.name ?? "")
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

    function setVolume(value: real): void {
        if (sink?.ready)
            sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function step(delta: real): void {
        setVolume(volume + delta);
    }

    function toggleMute(): void {
        if (sink?.ready)
            sink.audio.muted = !sink.audio.muted;
    }

    function setDefault(node: PwNode): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function openMixer(): void {
        Quickshell.execDetached(["pavucontrol"]);
    }

    // Volume and mute are only valid on tracked nodes
    PwObjectTracker {
        objects: [root.sink]
    }
}
