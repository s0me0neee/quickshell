import QtQuick
import Preview

QtObject {
    id: root

    property string name: ""
    property int type: DeviceType.Wifi
    property bool connected: false
    property bool hasLink: false
    property bool scannerEnabled: false

    default property list<WifiNetwork> networkList
    // list<T> is array-like but not an array, and Network.qml calls .filter/.sort on it
    readonly property var networks: ({
            values: Array.from(networkList)
        })
}
