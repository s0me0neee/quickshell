import QtQuick

QtObject {
    id: node

    property string name: ""
    property string description: ""
    property string nickname: ""
    property bool isSink: true
    property bool isStream: false
    property bool ready: true
    property var properties: ({})

    // Held here and aliased into `audio`, so a fake node can be set up in one line
    property real volume: 0.5
    property bool muted: false

    readonly property QtObject audio: QtObject {
        property alias volume: node.volume
        property alias muted: node.muted
    }
}
