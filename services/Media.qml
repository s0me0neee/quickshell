pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    // playerctld is a proxy that mirrors whichever player is active, so left in it shows
    // up as a second copy of one of the real players
    readonly property var players: Mpris.players.values.filter(p => !/playerctld/.test(p.dbusName ?? ""))
    // Playing first, then alphabetical, so the list doesn't reshuffle under the pointer
    readonly property var sorted: [...players].sort((a, b) => (b.isPlaying - a.isPlaying) || (a.identity ?? "").localeCompare(b.identity ?? ""))

    // What the user picked, held as its bus name rather than the object itself: when that
    // player quits the lookup below simply stops matching and the automatic choice takes
    // over. Holding the object left the whole bar showing a dead player's last track.
    property string chosenBus: ""
    readonly property MprisPlayer chosen: players.find(p => p.dbusName === chosenBus) ?? null

    // Prefer the pick, then whatever is playing, then anything with a track loaded
    readonly property MprisPlayer active: chosen ?? players.find(p => p.isPlaying) ?? players.find(p => p.trackTitle !== "") ?? null

    readonly property bool hasMedia: active !== null
    readonly property bool manyPlayers: players.length > 1
    readonly property bool playing: active?.isPlaying ?? false
    readonly property string title: active?.trackTitle ?? ""
    readonly property string artist: active?.trackArtist ?? ""
    readonly property string artUrl: active?.trackArtUrl ?? ""
    readonly property bool canGoNext: active?.canGoNext ?? false
    readonly property bool canGoPrevious: active?.canGoPrevious ?? false

    // Picking the one already showing hands control back to the automatic choice
    function choose(player: MprisPlayer): void {
        chosenBus = player?.dbusName === chosenBus ? "" : (player?.dbusName ?? "");
    }

    function cyclePlayer(): void {
        if (sorted.length < 2)
            return;
        const i = sorted.indexOf(active);
        chosenBus = sorted[(i + 1) % sorted.length]?.dbusName ?? "";
    }

    function togglePlaying(): void {
        if (active?.canTogglePlaying)
            active.togglePlaying();
    }

    function next(): void {
        if (active?.canGoNext)
            active.next();
    }

    function previous(): void {
        if (active?.canGoPrevious)
            active.previous();
    }
}
