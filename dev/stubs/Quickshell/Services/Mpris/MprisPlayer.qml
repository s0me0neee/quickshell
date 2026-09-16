import QtQuick

QtObject {
    id: root

    property string dbusName: ""
    property string identity: ""

    property bool isPlaying: false
    property string trackTitle: ""
    property string trackArtist: ""
    property string trackAlbum: ""
    property url trackArtUrl: ""

    property real length: 0
    property real position: 0

    property bool canGoNext: true
    property bool canGoPrevious: true
    property bool canTogglePlaying: true
    property bool canSeek: true

    property bool loopSupported: true
    property int loopState: MprisLoopState.None
    property bool shuffleSupported: true
    property bool shuffle: false

    function togglePlaying(): void {
        isPlaying = !isPlaying;
    }

    function next(): void {
        position = 0;
    }

    function previous(): void {
        position = 0;
    }

    // MPRIS doesn't push position either, but something has to move the bar along
    readonly property Timer ticker: Timer {
        running: root.isPlaying && root.length > 0
        repeat: true
        interval: 1000
        onTriggered: root.position = (root.position + 1) % root.length
    }
}
