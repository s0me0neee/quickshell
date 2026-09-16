pragma Singleton

import QtQuick
import Preview

QtObject {
    id: root

    // Writable so the panel's toggle really flips the radio; the scenario picks the start
    property bool wifiEnabled: !Preview.scene("wifioff")
    readonly property bool wifiHardwareEnabled: true
    // NetworkManager reports reachability, not hardware: nothing up means no connectivity
    property int connectivity: (wifi.connected || ethernet.connected) ? NetworkConnectivity.Full : NetworkConnectivity.None

    readonly property var devices: ({
            values: [wifi, ethernet]
        })

    function checkConnectivity(): void {
        console.log("[preview] checkConnectivity");
    }

    // Switching the radio off tears the connection down, the way NetworkManager does
    readonly property NetworkDevice wifi: NetworkDevice {
        name: "wlan0"
        type: DeviceType.Wifi
        connected: !Preview.scene("wired") && root.wifiEnabled
        scannerEnabled: false

        WifiNetwork {
            name: "home-5g"
            connected: !Preview.scene("wired") && root.wifiEnabled
            known: true
            signalStrength: 82
            state: ConnectionState.Connected
        }
        WifiNetwork {
            name: "home-2g"
            known: true
            signalStrength: 64
        }
        WifiNetwork {
            name: "Pixel_4821"
            signalStrength: 47
            security: WifiSecurityType.Sae
        }
        WifiNetwork {
            name: "CoffeeBar Guest"
            signalStrength: 31
            security: WifiSecurityType.Open
        }
        WifiNetwork {
            name: "eduroam"
            signalStrength: 18
            security: WifiSecurityType.Enterprise
        }
    }

    readonly property NetworkDevice ethernet: NetworkDevice {
        name: "enp3s0"
        type: DeviceType.Wired
        connected: Preview.scene("wired")
        hasLink: Preview.scene("wired")
    }
}
