pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland

// Holds the session awake on demand. hypridle dims the screen after 5 minutes, locks at
// 10 and suspends at 30 — right for a machine left alone, wrong for one being watched.
//
// This is the Wayland idle-inhibit protocol rather than a hypridle command, so it also
// stops anything else that honours it, and it lets go if the shell dies.
Singleton {
    id: root

    property alias enabled: props.enabled
    readonly property alias since: props.since

    // The line under "Keep awake" on its tile
    readonly property string status: enabled ? `Since ${Settings.time(props.since)}` : "Normal sleep"

    function toggle(): void {
        props.enabled = !props.enabled;
    }

    onEnabledChanged: {
        if (enabled)
            props.since = new Date();
    }

    // Outliving a config reload matters here more than anywhere else in the shell: the
    // whole point is a long sit, and reloading mid-film would quietly hand you back to
    // hypridle
    PersistentProperties {
        id: props

        property bool enabled: false
        property date since: new Date()

        reloadableId: "idleInhibit"
    }

    // The protocol inhibits on behalf of a surface, so there has to be one. Nothing is
    // drawn in it: zero size, and an empty mask so it can never take a click
    IdleInhibitor {
        enabled: props.enabled

        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            mask: Region {}

            WlrLayershell.namespace: "qs-idle"
        }
    }
}
