pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    // playerctld is a proxy that mirrors whichever player is active, so left in it shows
    // up as a second copy of one of the real players
    readonly property var players: Mpris.players.values.filter(p => !/playerctld/.test(p.dbusName ?? ""))
    // Alphabetical only: ordering by what is playing would reshuffle the chips under the
    // pointer every time something is paused
    readonly property var sorted: [...players].sort((a, b) => (a.identity ?? "").localeCompare(b.identity ?? ""))

    // Bus names of everything playing right now, watched so we can tell a player that
    // just *started* from one that merely happens to be playing
    readonly property var nowPlaying: players.filter(p => p.isPlaying).map(p => p.dbusName)
    property var wasPlaying: []
    // The player the bar follows when nothing is pinned. It only moves when some player
    // starts, so pausing the one on show no longer hands the bar to another app.
    property string autoBus: ""

    onNowPlayingChanged: {
        const started = nowPlaying.find(b => !wasPlaying.includes(b));
        wasPlaying = nowPlaying;
        if (started)
            autoBus = started;
    }

    // What the user picked, held as its bus name rather than the object itself: when that
    // player quits the lookup below simply stops matching and the automatic choice takes
    // over. Holding the object left the whole bar showing a dead player's last track.
    property string chosenBus: ""
    readonly property MprisPlayer chosen: players.find(p => p.dbusName === chosenBus) ?? null
    readonly property MprisPlayer followed: players.find(p => p.dbusName === autoBus) ?? null

    // The pick, then the player we are following, then anything playing or loaded
    readonly property MprisPlayer active: chosen ?? followed ?? players.find(p => p.isPlaying) ?? players.find(p => p.trackTitle !== "") ?? players[0] ?? null

    readonly property bool hasMedia: active !== null
    readonly property bool manyPlayers: players.length > 1
    readonly property bool playing: active?.isPlaying ?? false
    readonly property string title: active?.trackTitle ?? ""
    readonly property string artist: active?.trackArtist ?? ""
    readonly property string album: active?.trackAlbum ?? ""
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

    IpcHandler {
        target: "media"

        function state(): string {
            return JSON.stringify({
                players: root.players.map(p => ({ bus: p.dbusName, id: p.identity, playing: p.isPlaying, title: p.trackTitle })),
                chosenBus: root.chosenBus,
                autoBus: root.autoBus,
                activeBus: root.active?.dbusName ?? null,
                title: root.title
            }, null, 1);
        }
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
