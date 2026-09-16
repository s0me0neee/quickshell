pragma Singleton

import QtQuick
import Preview

QtObject {
    id: root

    readonly property var players: ({
            values: Preview.scene("media") ? [spotify, firefox] : []
        })

    readonly property MprisPlayer spotify: MprisPlayer {
        dbusName: "org.mpris.MediaPlayer2.spotify"
        identity: "Spotify"
        isPlaying: true
        trackTitle: "Weightless"
        trackArtist: "Marconi Union"
        trackAlbum: "Distance"
        trackArtUrl: Preview.artwork
        length: 488
        position: 96
    }

    readonly property MprisPlayer firefox: MprisPlayer {
        dbusName: "org.mpris.MediaPlayer2.firefox.instance_1"
        identity: "Firefox"
        isPlaying: false
        trackTitle: "How Quickshell draws a bar"
        trackArtist: "some conference talk"
        length: 2730
        position: 611
        shuffleSupported: false
    }
}
