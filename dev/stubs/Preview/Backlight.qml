pragma Singleton

import QtQuick
import Preview

// A fake brightnessctl: holds the backlight state the Process stub answers queries with,
// so the real Brightness.qml can be driven end to end without a kernel behind it.
QtObject {
    id: root

    // The `desktop` scenario has no panel to dim, so brightnessctl finds no backlight
    readonly property bool present: !Preview.scene("desktop")
    // Two of them under `multibacklight`, which is what an eDP + a DDC monitor looks like
    readonly property bool several: Preview.scene("multibacklight")

    property int raw: 2400
    property int max: 4000
    property int secondRaw: 40
    property int secondMax: 100

    function line(name: string, current: int, ceiling: int): string {
        return `${name},backlight,${current},${Math.round(current * 100 / ceiling)}%,${ceiling}`;
    }

    // What `brightnessctl -m` prints for the devices it can see
    function list(): string {
        if (!present)
            return "";
        const out = [line("intel_backlight", raw, max)];
        if (several)
            out.push(line("ddcci6", secondRaw, secondMax));
        return out.join("\n") + "\n";
    }

    // `brightnessctl -m -d NAME set N` applies the value and echoes the device's new state
    function set(name: string, value: int): string {
        if (name === "ddcci6") {
            secondRaw = Math.max(0, Math.min(secondMax, value));
            return line(name, secondRaw, secondMax) + "\n";
        }
        raw = Math.max(0, Math.min(max, value));
        return line("intel_backlight", raw, max) + "\n";
    }
}
