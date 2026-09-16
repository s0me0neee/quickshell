pragma Singleton

import QtQuick
import Quickshell

// Nerd Font glyphs (Material Design set). Every codepoint here is present in FiraCode Nerd Font v3.
Singleton {
    readonly property string power: "\u{F0425}"
    readonly property string restart: "\u{F0709}"
    readonly property string logout: "\u{F0343}"
    readonly property string suspend: "\u{F04B2}"
    readonly property string hibernate: "\u{F0717}"

    readonly property string workspace: ""
    readonly property string workspaceActive: "\u{F070B}"

    readonly property string play: "\u{F040A}"
    readonly property string pause: "\u{F03E4}"
    readonly property string previous: "\u{F04AE}"
    readonly property string next: "\u{F04AD}"
    readonly property string music: "\u{F075A}"
    readonly property string bolt: ""
    readonly property string shuffle: "\u{F049D}"
    readonly property string repeat: "\u{F0456}"
    readonly property string repeatOnce: "\u{F0458}"
    readonly property list<string> brightness: ["\u{F00DE}", "\u{F00DF}", "\u{F00E0}"]
    readonly property string calendar: "\u{F00ED}"

    readonly property list<string> volume: ["\u{F057F}", "\u{F0580}", "\u{F057E}"]
    readonly property string volumeMuted: "\u{F075F}"
    readonly property string headphones: "\u{F02CB}"
    readonly property string speaker: "\u{F04C3}"
    readonly property string mixer: "\u{F062E}"
    readonly property string mic: "\u{F036C}"
    readonly property string micMuted: "\u{F036D}"
    readonly property string apps: "\u{F0570}"

    readonly property string checkOn: "\u{F0132}"
    readonly property string checkOff: "\u{F0131}"
    readonly property string radioOn: "\u{F043E}"
    readonly property string radioOff: "\u{F043D}"
    readonly property string chevronLeft: "\u{F0141}"
    readonly property string chevronRight: "\u{F0142}"
    readonly property string chevronDown: "\u{F0140}"
    readonly property string back: "\u{F004D}"
    readonly property string lock: "\u{F033E}"
    readonly property string globe: "\u{F059F}"
    readonly property string check: "\u{F012C}"
    readonly property string close: "\u{F0156}"
    readonly property string clearAll: "\u{F05E8}"
    readonly property string eye: "\u{F0208}"
    readonly property string eyeOff: "\u{F0209}"
    readonly property string refresh: "\u{F0453}"
    readonly property string settings: "\u{F0493}"
    readonly property string alert: "\u{F0026}"

    readonly property list<string> wifi: ["\u{F092F}", "\u{F091F}", "\u{F0922}", "\u{F0925}", "\u{F0928}"]
    readonly property string wifiOff: "\u{F092E}"
    readonly property string ethernet: "\u{F0200}"

    // 0%, 10% ... 90%, then full
    readonly property list<string> battery: ["\u{F007A}", "\u{F007A}", "\u{F007B}", "\u{F007C}", "\u{F007D}", "\u{F007E}", "\u{F007F}", "\u{F0080}", "\u{F0081}", "\u{F0082}", "\u{F0079}"]
    readonly property string batteryCharging: "\u{F0084}"
    readonly property string plug: "\u{F06A5}"

    readonly property string profilePowerSaver: "\u{F032A}"
    readonly property string profileBalanced: "\u{F0F85}"
    readonly property string profilePerformance: "\u{F04C5}"

    // Keys match swaync-client's "alt" field
    readonly property var notifications: ({
            "notification": "\u{F116B}",
            "none": "\u{F009C}",
            "dnd-notification": "\u{F00A0}",
            "dnd-none": "\u{F0A93}",
            "inhibited-notification": "\u{F009B}",
            "inhibited-none": "\u{F0A91}",
            "dnd-inhibited-notification": "\u{F009B}",
            "dnd-inhibited-none": "\u{F0A91}"
        })

    function pick(list: var, fraction: real): string {
        const i = Math.round(Math.max(0, Math.min(1, fraction)) * (list.length - 1));
        return list[i];
    }
}
