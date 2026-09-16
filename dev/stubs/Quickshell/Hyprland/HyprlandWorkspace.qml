import QtQuick

QtObject {
    id: root

    // `id` is only reserved as an assignment; a property called that is fine, it just
    // has to be set from createObject rather than declaratively
    property int id: 0
    property string name: ""
    property bool urgent: false
    property bool active: false
    property var monitor: null

    // How many windows this workspace is pretending to hold
    property int windows: 0
    readonly property var toplevels: ({
            values: Array.from({
                length: windows
            }, () => ({
                    lastIpcObject: {
                        fullscreen: 0
                    }
                }))
        })
}
