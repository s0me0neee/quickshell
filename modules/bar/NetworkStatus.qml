import QtQuick
import Quickshell.Networking as NM
import qs.common
import qs.components
import qs.services

// Left click: network panel. Right click: NetworkManager's advanced settings.
CircleButton {
    id: root

    required property QtObject bar

    readonly property bool noInternet: Network.connected && (Network.connectivity === NM.NetworkConnectivity.None || Network.connectivity === NM.NetworkConnectivity.Limited || Network.connectivity === NM.NetworkConnectivity.Portal)

    visible: Settings.data.showNetwork
    icon: {
        if (Network.wired)
            return Icons.ethernet;
        return Network.connected ? Icons.pick(Icons.wifi, Network.strength) : Icons.wifiOff;
    }
    fill: !Network.connected ? Theme.tonal : noInternet ? Theme.accentSoft : Theme.accent
    iconColor: {
        if (!Network.connected)
            return Network.wifiEnabled ? Theme.critical : Theme.secondaryContainerText;
        return noInternet ? Theme.tertiaryContainerText : Theme.primaryContainerText;
    }
    active: panel.open
    tooltip: panel.open ? "" : `${Network.name}\n${Network.connectivityText}`
    onClicked: mouse => mouse.button === Qt.RightButton ? Network.openAdvanced() : panel.toggle()

    NetworkPanel {
        id: panel

        target: root
        bar: root.bar
    }
}
