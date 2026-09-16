pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

Singleton {
    id: root

    readonly property var devices: Networking.devices.values

    // --- wifi ---
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wifiNetwork: wifiDevice?.networks.values.find(n => n.connected) ?? null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardwareBlocked: !Networking.wifiHardwareEnabled
    readonly property bool scanning: wifiDevice?.scannerEnabled ?? false
    // Connected first, then saved networks, then strongest signal
    readonly property var networks: (wifiDevice?.networks.values ?? []).filter(n => n.name !== "").sort((a, b) => (b.connected - a.connected) || (b.known - a.known) || (b.signalStrength - a.signalStrength))

    // --- ethernet ---
    readonly property var wiredDevices: devices.filter(d => d.type === DeviceType.Wired)
    readonly property var wiredDevice: wiredDevices.find(d => d.connected) ?? wiredDevices.find(d => d.hasLink) ?? wiredDevices[0] ?? null
    readonly property bool wired: wiredDevice?.connected ?? false

    // --- overall ---
    readonly property bool connected: wired || wifiNetwork !== null
    readonly property string name: wired ? "Ethernet" : (wifiNetwork?.name ?? (wifiEnabled ? "Disconnected" : "Wi-Fi off"))
    readonly property real strength: wifiNetwork?.signalStrength ?? 0
    readonly property var activeDevice: wired ? wiredDevice : (wifiNetwork ? wifiDevice : null)
    readonly property int connectivity: Networking.connectivity
    readonly property string connectivityText: {
        switch (connectivity) {
        case NetworkConnectivity.Full:
            return "Connected to the internet";
        case NetworkConnectivity.Limited:
            return "Limited connectivity";
        case NetworkConnectivity.Portal:
            return "Sign-in required";
        case NetworkConnectivity.None:
            return connected ? "No internet access" : "Not connected";
        default:
            return connected ? "Connected" : "Not connected";
        }
    }
    property string ipAddress: ""

    function setWifiEnabled(enabled: bool): void {
        Networking.wifiEnabled = enabled;
    }

    // True when connecting needs a password the system doesn't have yet
    function needsPassword(network: var): bool {
        const s = network.security;
        return !network.known && (s === WifiSecurityType.WpaPsk || s === WifiSecurityType.Wpa2Psk || s === WifiSecurityType.Sae);
    }

    function isSecured(network: var): bool {
        return network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe;
    }

    function failText(reason: int): string {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
            return "Wrong password";
        case ConnectionFailReason.WifiAuthTimeout:
            return "Timed out";
        case ConnectionFailReason.WifiNetworkLost:
            return "Network lost";
        default:
            return "Couldn't connect";
        }
    }

    function refresh(): void {
        Networking.checkConnectivity();
        refreshIp();
    }

    function refreshIp(): void {
        if (!activeDevice?.name) {
            ipAddress = "";
            return;
        }
        ipProc.command = ["ip", "-j", "-4", "addr", "show", "dev", activeDevice.name];
        ipProc.running = true;
    }

    function openPortal(): void {
        Quickshell.execDetached(["xdg-open", "http://neverssl.com"]);
    }

    function openAdvanced(): void {
        Quickshell.execDetached(["nm-connection-editor"]);
    }

    onActiveDeviceChanged: refreshIp()
    onConnectedChanged: refreshIp()

    Process {
        id: ipProc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const info = JSON.parse(text)[0]?.addr_info?.[0];
                    root.ipAddress = info ? `${info.local}/${info.prefixlen}` : "";
                } catch (e) {
                    root.ipAddress = "";
                }
            }
        }
    }
}
