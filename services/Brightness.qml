pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // brightnessctl -m prints one CSV line per device: name,class,current,percent%,max
    property var devices: []
    property string device: ""
    property int max: 0
    property int raw: 0

    readonly property bool available: device !== "" && max > 0
    readonly property real brightness: max > 0 ? raw / max : 0
    readonly property int percent: Math.round(brightness * 100)

    // Never all the way off: a black panel with no visible slider is a trap
    readonly property real minimum: 0.01

    function set(value: real): void {
        if (!available)
            return;
        // Optimistic, so the slider tracks the drag instead of the process round trip
        raw = Math.round(Math.max(minimum, Math.min(1, value)) * max);
        writeTimer.restart();
    }

    function step(delta: real): void {
        set(brightness + delta);
    }

    function setDevice(name: string): void {
        select(name);
        refresh();
    }

    // Re-runs brightnessctl to pick up devices appearing or disappearing. The level
    // itself is watched, so this is only needed when the device list might have changed
    function refresh(): void {
        if (!writeTimer.running && !setProc.running)
            listProc.running = true;
    }

    function parse(text: string): var {
        return text.trim().split("\n").map(line => line.split(",")).filter(f => f.length >= 5 && f[1] === "backlight").map(f => ({
                    name: f[0],
                    raw: parseInt(f[2]),
                    max: parseInt(f[4])
                }));
    }

    function select(name: string): void {
        const found = devices.find(d => d.name === name) ?? devices[0] ?? null;
        device = found?.name ?? "";
        max = found?.max ?? 0;
        raw = found?.raw ?? 0;
    }

    Component.onCompleted: refresh()

    // The brightness keys and hypridle run brightnessctl themselves, so the level moves
    // behind our back most of the time. sysfs does raise inotify events on this file, so
    // watching it keeps the ring honest without a poll or a second process.
    FileView {
        id: level

        path: root.device === "" ? "" : `/sys/class/backlight/${root.device}/actual_brightness`
        watchChanges: true
        // A write of our own comes back through here too; the queued value wins until
        // it has actually been handed to the hardware
        onFileChanged: reload()
        onLoaded: {
            if (writeTimer.running || setProc.running)
                return;
            const value = parseInt(text());
            if (!isNaN(value))
                root.raw = value;
        }
    }

    // One write per burst: a drag would otherwise spawn a process per mouse move
    Timer {
        id: writeTimer

        interval: 40
        onTriggered: {
            if (setProc.running) {
                restart();
                return;
            }
            setProc.command = ["brightnessctl", "-m", "-d", root.device, "set", `${root.raw}`];
            setProc.running = true;
        }
    }

    Process {
        id: listProc

        command: ["brightnessctl", "-m", "-l"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.devices = root.parse(text);
                root.select(root.device);
            }
        }
    }

    Process {
        id: setProc

        stdout: StdioCollector {
            // brightnessctl echoes the device's new state; the hardware has the last word,
            // but not over a write that is already queued behind this one
            onStreamFinished: {
                const applied = root.parse(text)[0];
                if (applied && applied.name === root.device && !writeTimer.running)
                    root.raw = applied.raw;
            }
        }
    }
}
