pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

// The polkit authentication agent, in place of polkit-gnome. Only one agent can hold
// the session, so polkit-gnome has to be stopped for this one to register.
Singleton {
    id: root

    readonly property bool registered: agent.isRegistered
    readonly property AuthFlow flow: agent.flow
    readonly property bool open: agent.isActive && flow !== null

    // What the loader in shell.qml keys off; see Settings.menuLive for why the linger
    // is counted here and not read from the window
    readonly property bool live: open || linger.running

    onOpenChanged: {
        if (!open)
            linger.restart();
    }

    Timer {
        id: linger

        interval: 450
    }

    function submit(response: string): void {
        if (flow && flow.isResponseRequired)
            flow.submit(response);
    }

    function cancel(): void {
        if (flow)
            flow.cancelAuthenticationRequest();
    }

    PolkitAgent {
        id: agent
    }
}
