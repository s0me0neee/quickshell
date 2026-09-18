import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking as NM
import qs.common
import qs.components
import qs.services

// Wi-Fi, Ethernet and internet status. Scans only while open.
Popout {
    id: root

    // The network row showing its actions / password field
    property var expanded: null

    contentWidth: 340
    wantsKeyboard: true

    // Connections rather than a handler on the root: a handler here would replace
    // Popout's own onVisibleChanged, which is what gives the surface its height back
    // once it is off screen
    Connections {
        target: root

        function onVisibleChanged(): void {
            if (root.visible)
                Network.refresh();
            else
                root.expanded = null;
        }
    }

    // Scan for networks only while the panel is on screen
    Binding {
        target: Network.wifiDevice
        property: "scannerEnabled"
        value: root.visible
        when: Network.wifiDevice !== null
    }

    // --- header ---

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing + 2

        Icon {
            text: Network.wifiEnabled ? Icons.wifi[4] : Icons.wifiOff
            size: 20
            color: Network.wifiEnabled ? Theme.primary : Theme.surfaceVariantText
        }

        StyledText {
            Layout.fillWidth: true
            text: "Wi-Fi"
            font.pixelSize: Appearance.fontSize + 2
            font.weight: Font.DemiBold
        }

        Toggle {
            checked: Network.wifiEnabled
            enabled: !Network.wifiHardwareBlocked
            onToggled: Network.setWifiEnabled(!Network.wifiEnabled)
        }
    }

    // --- internet status card ---

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacingSmall
        implicitHeight: status.implicitHeight + Appearance.spacingLarge * 2 - 4
        radius: Appearance.radiusItem + 2
        color: Qt.alpha(Theme.surfaceContainerHighest, 0.5)

        ColumnLayout {
            id: status

            anchors.fill: parent
            anchors.margins: Appearance.spacingLarge - 2
            spacing: Appearance.spacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacingLarge

                // Status dot with a soft halo
                Item {
                    implicitWidth: 18
                    implicitHeight: 18

                    readonly property color tone: {
                        if (Network.connectivity === NM.NetworkConnectivity.Full)
                            return Theme.primary;
                        return Network.connected ? Theme.tertiary : Theme.critical;
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.alpha(parent.tone, 0.22)

                        Behavior on color {
                            CAnim {}
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 8
                        height: 8
                        radius: 4
                        color: parent.tone

                        Behavior on color {
                            CAnim {}
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Network.connectivityText
                        font.weight: Font.DemiBold
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: {
                            if (!Network.activeDevice)
                                return "";
                            const parts = [Network.activeDevice.name];
                            if (Network.ipAddress)
                                parts.push(Network.ipAddress);
                            return parts.join(" · ");
                        }
                        color: Theme.textDim
                        font.pixelSize: Appearance.fontSizeSmall
                    }
                }

                MouseArea {
                    id: refresh

                    implicitWidth: 28
                    implicitHeight: 28
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        spin.restart();
                        Network.refresh();
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: refresh.containsMouse ? Qt.alpha(Theme.surfaceText, 0.1) : "transparent"
                    }

                    Icon {
                        id: refreshIcon

                        anchors.centerIn: parent
                        text: Icons.refresh
                        size: 16
                        color: Theme.surfaceVariantText

                        RotationAnimation on rotation {
                            id: spin

                            running: false
                            from: 0
                            to: 360
                            duration: Appearance.animSlow + 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Ethernet line (only if the machine has a wired port)
            RowLayout {
                Layout.fillWidth: true
                visible: Network.wiredDevice !== null
                spacing: Appearance.spacingLarge

                Icon {
                    Layout.preferredWidth: 18
                    text: Icons.ethernet
                    size: 15
                    color: Network.wired ? Theme.primary : Theme.textDim
                }

                StyledText {
                    Layout.fillWidth: true
                    text: {
                        const dev = Network.wiredDevice;
                        if (!dev)
                            return "";
                        if (dev.connected)
                            return dev.linkSpeed > 0 ? `Ethernet · ${dev.linkSpeed} Mb/s` : "Ethernet · Connected";
                        return dev.hasLink ? "Ethernet · Cable plugged in, not active" : "Ethernet · Cable unplugged";
                    }
                    color: Network.wired ? Theme.surfaceText : Theme.textDim
                    font.pixelSize: Appearance.fontSizeSmall
                }
            }

            Button {
                Layout.fillWidth: true
                visible: Network.connectivity === NM.NetworkConnectivity.Portal
                text: "Open sign-in page"
                filled: true
                onClicked: {
                    root.open = false;
                    Network.openPortal();
                }
            }
        }
    }

    // --- networks ---

    StyledText {
        Layout.topMargin: Appearance.spacingSmall
        visible: Network.wifiEnabled
        text: Network.networks.length > 0 ? "Networks" : "Searching for networks…"
        color: Theme.surfaceVariantText
        font.pixelSize: Appearance.fontSizeSmall
    }

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 320)
        visible: Network.wifiEnabled
        clip: true
        spacing: 2
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds

        model: ScriptModel {
            values: Network.networks
        }

        add: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Appearance.animNormal
            }

            NumberAnimation {
                property: "x"
                from: -16
                to: 0
                duration: Appearance.animSlow
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.curveEmphasized
            }
        }

        remove: Transition {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: Appearance.animFast
            }
        }

        displaced: Transition {
            NumberAnimation {
                property: "y"
                duration: Appearance.animNormal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.curveStandard
            }

            NumberAnimation {
                property: "opacity"
                to: 1
                duration: Appearance.animFast
            }
        }

        move: displaced

        delegate: NetworkRow {
            width: list.width
        }
    }

    StyledText {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing
        Layout.bottomMargin: Appearance.spacing
        visible: !Network.wifiEnabled
        horizontalAlignment: Text.AlignHCenter
        text: Network.wifiHardwareBlocked ? "Wi-Fi is blocked by a hardware switch" : "Wi-Fi is off"
        color: Theme.textDim
    }

    Divider {}

    ListItem {
        icon: Icons.settings
        label: "Advanced settings"
        onActivated: {
            root.open = false;
            Network.openAdvanced();
        }
    }

    component NetworkRow: ColumnLayout {
        id: row

        required property var modelData
        // The network object can be gone while the row plays its remove animation
        readonly property var net: modelData ?? null
        readonly property bool isExpanded: !!net && root.expanded === net
        readonly property bool isConnected: net?.connected ?? false
        readonly property bool isKnown: net?.known ?? false
        readonly property bool busy: (net?.stateChanging ?? false) || net?.state === NM.ConnectionState.Connecting
        readonly property bool askPassword: !!net && !isConnected && Network.needsPassword(net)
        property string error: ""

        function activate(): void {
            if (!net)
                return;
            error = "";
            if (net.connected || askPassword) {
                root.expanded = isExpanded ? null : net;
                if (root.expanded && askPassword)
                    password.focusInput();
            } else {
                root.expanded = null;
                net.connect();
            }
        }

        function submit(): void {
            if (!net)
                return;
            error = "";
            if (net.connected) {
                net.disconnect();
                root.expanded = null;
            } else if (askPassword) {
                if (password.text.length < 8) {
                    password.invalid = true;
                    password.shake();
                    return;
                }
                net.connectWithPsk(password.text);
            } else {
                net.connect();
            }
        }

        height: implicitHeight
        spacing: 0

        Connections {
            target: row.net

            function onConnectionFailed(reason: int): void {
                row.error = Network.failText(reason);
                if (reason === NM.ConnectionFailReason.NoSecrets) {
                    root.expanded = row.net;
                    password.invalid = true;
                    password.shake();
                    password.focusInput();
                }
            }

            function onConnectedChanged(): void {
                if (row.isConnected) {
                    row.error = "";
                    password.text = "";
                    if (root.expanded === row.net)
                        root.expanded = null;
                }
            }
        }

        ListItem {
            icon: Icons.pick(Icons.wifi, row.net?.signalStrength ?? 0)
            label: row.net?.name ?? ""
            subtitle: {
                if (row.busy)
                    return "Connecting…";
                if (row.error)
                    return row.error;
                if (row.isConnected)
                    return "Connected";
                return row.isKnown ? "Saved" : "";
            }
            highlighted: row.isConnected
            onActivated: row.activate()

            Spinner {
                visible: row.busy
                size: 14
            }

            Icon {
                visible: !row.busy && row.isConnected
                text: Icons.check
                size: 16
                color: Theme.primary
            }

            Icon {
                visible: !row.busy && !row.isConnected && !!row.net && Network.isSecured(row.net)
                text: Icons.lock
                size: 13
                color: Theme.textDim
            }

            Icon {
                visible: row.isConnected || row.askPassword
                text: Icons.chevronDown
                size: 16
                color: Theme.textDim
                rotation: row.isExpanded ? 180 : 0

                Behavior on rotation {
                    Anim {
                        easing.bezierCurve: Appearance.curveEmphasized
                    }
                }
            }
        }

        // Actions / password, slides open under the row
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: row.isExpanded ? actions.implicitHeight + Appearance.spacing * 2 : 0
            clip: true
            opacity: row.isExpanded ? 1 : 0

            Behavior on Layout.preferredHeight {
                Anim {
                    easing.bezierCurve: Appearance.curveEmphasized
                }
            }

            Behavior on opacity {
                Anim {
                    duration: Appearance.animFast
                }
            }

            ColumnLayout {
                id: actions

                y: Appearance.spacing
                x: Appearance.spacing
                width: parent.width - Appearance.spacing * 2
                spacing: Appearance.spacing

                TextField {
                    id: password

                    visible: row.askPassword
                    password: true
                    placeholder: "Password"
                    onAccepted: row.submit()
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing

                    Button {
                        visible: row.isKnown
                        text: "Forget"
                        tone: Theme.critical
                        onClicked: {
                            root.expanded = null;
                            row.net?.forget();
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Button {
                        visible: !row.isConnected
                        text: "Cancel"
                        onClicked: root.expanded = null
                    }

                    Button {
                        text: row.isConnected ? "Disconnect" : "Connect"
                        filled: true
                        enabled: !row.busy
                        onClicked: row.submit()
                    }
                }
            }
        }
    }
}
