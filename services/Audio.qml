pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    // PipeWire tags a Bluetooth sink with the bluez5 device API; the node name is the
    // fallback for one whose device properties haven't been filled in yet
    readonly property bool bluetooth: (sink?.properties?.["device.api"] ?? "") === "bluez5" || /^bluez/i.test(sink?.name ?? "")
    readonly property bool headphones: /headphone|headset/i.test(sink?.name ?? "")
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)

    // The microphone, mirrored from the sink side
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false
    readonly property bool hasMic: source !== null
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio)

    // Playback streams: one per app making noise right now
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isStream && n.isSink && n.audio)

    // An app name worth showing: PipeWire gives us a properties dict on most streams
    function streamName(node: PwNode): string {
        return node?.properties?.["application.name"] || node?.description || node?.nickname || node?.name || "";
    }

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

    function setMicVolume(value: real): void {
        if (source?.ready)
            source.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMicMute(): void {
        if (source?.ready)
            source.audio.muted = !source.audio.muted;
    }

    function setStreamVolume(node: PwNode, value: real): void {
        if (node?.ready)
            node.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleStreamMute(node: PwNode): void {
        if (node?.ready)
            node.audio.muted = !node.audio.muted;
    }

    function setDefault(node: PwNode): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setDefaultSource(node: PwNode): void {
        Pipewire.preferredDefaultAudioSource = node;
    }

    function openMixer(): void {
        Quickshell.execDetached(["pavucontrol"]);
    }

    // Volume and mute are only valid on tracked nodes, so every node whose level we
    // show has to be in here — the streams list changes as apps come and go
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.streams]
    }
}
