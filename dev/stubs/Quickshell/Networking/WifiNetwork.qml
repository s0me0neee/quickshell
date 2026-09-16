import QtQuick

QtObject {
    id: root

    property string name: ""
    property bool connected: false
    property bool known: false
    property int signalStrength: 0
    property int security: WifiSecurityType.Wpa2Psk
    property int state: ConnectionState.Disconnected
    property bool stateChanging: false

    signal connectionFailed(int reason)

    function connect(): void {
        console.log("[preview] connect:", name);
    }

    function connectWithPsk(psk: string): void {
        console.log("[preview] connect with psk:", name);
    }

    function disconnect(): void {
        console.log("[preview] disconnect:", name);
    }

    function forget(): void {
        console.log("[preview] forget:", name);
    }
}
