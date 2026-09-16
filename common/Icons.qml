pragma Singleton

import QtQuick
import Quickshell

// Material Symbols Rounded, by codepoint. The font addresses icons by ligature name
// ("wifi", "volume_up") but this Qt build never applies the ligature, rendering the
// name as literal text, so every glyph is referenced by its codepoint instead. Each one
// below was rendered against the installed font to confirm it is the icon it claims.
Singleton {
    readonly property string power: "\uF8C7"
    readonly property string restart: "\uF053"
    readonly property string logout: "\uE9BA"
    readonly property string suspend: "\uF159"
    readonly property string hibernate: "\uEB3B"
    readonly property string lock: "\uE899"

    readonly property string play: "\uE037"
    readonly property string pause: "\uE034"
    readonly property string previous: "\uE045"
    readonly property string next: "\uE044"
    readonly property string music: "\uE405"
    readonly property string bolt: "\uEA0B"
    readonly property string shuffle: "\uE043"
    readonly property string repeat: "\uE040"
    readonly property string repeatOnce: "\uE041"
    readonly property list<string> brightness: ["\uE1AD", "\uE1AE", "\uE1AC"]
    readonly property string calendar: "\uEBCC"

    readonly property list<string> volume: ["\uE04E", "\uE04D", "\uE050"]
    readonly property string volumeMuted: "\uE04F"
    readonly property string headphones: "\uF01F"
    readonly property string speaker: "\uE32D"
    readonly property string mixer: "\uE429"
    readonly property string mic: "\uE31D"
    readonly property string micMuted: "\uE02B"

    readonly property string checkOn: "\uE9DE"
    readonly property string checkOff: "\uE835"
    readonly property string radioOn: "\uE837"
    readonly property string radioOff: "\uE836"
    readonly property string chevronRight: "\uE5CC"
    readonly property string chevronDown: "\uE5CF"
    readonly property string back: "\uE5C4"
    readonly property string globe: "\uEA07"
    readonly property string check: "\uE668"
    readonly property string eye: "\uE8F4"
    readonly property string eyeOff: "\uE8F5"
    readonly property string refresh: "\uE5D5"
    readonly property string settings: "\uE8B8"
    readonly property string alert: "\uF083"
    readonly property string close: "\uE5CD"
    readonly property string clearAll: "\uE0B8"
    readonly property string openExternal: "\uE89E"

    readonly property list<string> wifi: ["\uF0B0", "\uEBE4", "\uEBD6", "\uEBE1", "\uF065"]
    readonly property string wifiOff: "\uE648"
    readonly property string ethernet: "\uE8BE"
    readonly property string bluetooth: "\uE1A7"
    readonly property string bluetoothOff: "\uE1A9"

    // 0% through full
    readonly property list<string> battery: ["\uEBDC", "\uF09C", "\uF09D", "\uF09E", "\uF09F", "\uF0A0", "\uF0A1", "\uE1A5"]
    readonly property string batteryCharging: "\uE1A3"
    readonly property string plug: "\uE63C"

    readonly property string profilePowerSaver: "\uEC1A"
    readonly property string profileBalanced: "\uEAF6"
    readonly property string profilePerformance: "\uE9E4"

    // Keyed by whether anything is waiting and whether do-not-disturb is on
    readonly property var notifications: ({
            "notification": "\uE7F7",
            "none": "\uE7F5",
            "dnd-notification": "\uE7F8",
            "dnd-none": "\uE7F6"
        })

    function pick(list: var, fraction: real): string {
        const i = Math.round(Math.max(0, Math.min(1, fraction)) * (list.length - 1));
        return list[i];
    }
}
