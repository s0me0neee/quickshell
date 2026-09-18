import QtQuick
import Quickshell
import Quickshell.Networking as NM
import qs.common
import qs.components
import qs.services

// Left click: network panel. Right click: NetworkManager's advanced settings.
CircleButton {
    id: root

    required property QtObject bar

    property bool panelOpen: false
    readonly property bool panelLive: panelOpen || panelLinger.running

    onPanelOpenChanged: {
        if (panelOpen)
            panelLinger.stop();
        else
            panelLinger.restart();
        // Applied imperatively, not bound: a panel created already-open would miss its
        // openChanged, which is what claims PopoutState and runs the open animation.
        if (panelLoader.item)
            panelLoader.item.open = root.panelOpen;
    }

    Timer {
        id: panelLinger

        interval: Appearance.animNormal + 80
    }

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
    active: root.panelOpen
    tooltip: root.panelOpen ? "" : `${Network.name}\n${Network.connectivityText}`
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton)
            Network.openAdvanced();
        else
            root.panelOpen = !root.panelOpen;
    }

    LazyLoader {
        id: panelLoader

        active: root.panelLive

        NetworkPanel {
            id: panel

            target: root
            bar: root.bar
        }
    }

    Connections {
        target: panelLoader

        // The panel is created a moment after `active` flips; push the current state in
        // then, so it opens (with its animation) the first time it exists.
        function onItemChanged(): void {
            if (panelLoader.item)
                panelLoader.item.open = root.panelOpen;
        }
    }

    // The panel closes itself when another popout claims PopoutState; keep the button's
    // own idea of "open" in step with whatever the panel actually did.
    Connections {
        target: panelLoader.item

        function onOpenChanged(): void {
            if (panelLoader.item && root.panelOpen !== panelLoader.item.open)
                root.panelOpen = panelLoader.item.open;
        }
    }
}
