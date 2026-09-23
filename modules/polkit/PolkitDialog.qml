import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

// The polkit password prompt. A stray click outside never cancels it, so a half-typed
// password isn't lost; Escape and the Cancel button do.
PanelWindow {
    id: root

    property real progress: 0
    // Copied out of the flow, which is gone before the close animation finishes
    property string message
    property bool waiting: false

    readonly property AuthFlow flow: Polkit.flow
    readonly property var identities: flow ? flow.identities : []

    Component.onCompleted: progress = Qt.binding(() => Polkit.open ? 1 : 0)

    onFlowChanged: {
        if (!flow)
            return;
        message = flow.message;
        waiting = false;
        field.text = "";
    }

    function submit(): void {
        if (!flow || !flow.isResponseRequired || waiting)
            return;
        waiting = true;
        Polkit.submit(field.text);
    }

    function identityName(identity: var): string {
        return identity ? identity.displayName || identity.name || "" : "";
    }

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "qs-polkit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Polkit.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Behavior on progress {
        Anim {
            duration: Polkit.open ? Appearance.animSlow : Appearance.animNormal
            easing.bezierCurve: Polkit.open ? Appearance.curveEmphasized : Appearance.curveStandard
        }
    }

    Connections {
        target: root.flow

        function onAuthenticationFailed(): void {
            root.waiting = false;
            field.text = "";
            field.invalid = true;
            field.shake();
            field.focusInput();
        }

        // The flow asks again after a failure; that is the moment the field is live
        function onIsResponseRequiredChanged(): void {
            if (root.flow.isResponseRequired) {
                root.waiting = false;
                field.focusInput();
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.surface, 0.5)
        opacity: root.progress

        // Swallows clicks so nothing underneath is hit, and cancels nothing
        MouseArea {
            anchors.fill: parent
        }
    }

    Shortcut {
        sequences: ["Escape"]
        context: Qt.WindowShortcut
        onActivated: Polkit.cancel()
    }

    Rectangle {
        id: panel

        anchors.centerIn: parent
        width: Math.min(parent.width - 48, 420)
        implicitHeight: content.implicitHeight + 2 * 20
        height: implicitHeight
        radius: Appearance.radiusPanel
        color: Theme.panel
        border.width: 1
        border.color: Qt.alpha(Theme.outlineVariant, 0.7)
        opacity: root.progress
        scale: 0.96 + 0.04 * root.progress

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: 20
            spacing: Appearance.spacingLarge

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 52
                implicitHeight: 52
                radius: width / 2
                color: Theme.accentSoft

                Icon {
                    anchors.centerIn: parent
                    text: Icons.lock
                    size: 24
                    color: Theme.primary
                }
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "Authentication required"
                font.pixelSize: Appearance.fontSize + 3
                font.weight: Font.DemiBold
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.message
                color: Theme.surfaceVariantText
                wrapMode: Text.Wrap
                elide: Text.ElideNone
            }

            // Only worth showing when polkit accepts more than one admin
            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacingSmall
                visible: root.identities.length > 1
                spacing: Appearance.spacingSmall

                Repeater {
                    model: root.identities

                    Button {
                        required property var modelData

                        text: root.identityName(modelData)
                        filled: root.flow && root.flow.selectedIdentity === modelData
                        onClicked: {
                            root.flow.selectedIdentity = modelData;
                            field.focusInput();
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                visible: root.identities.length === 1
                text: `as ${root.identityName(root.flow?.selectedIdentity)}`
                color: Theme.textDim
                font.pixelSize: Appearance.fontSizeSmall
            }

            TextField {
                id: field

                Layout.topMargin: Appearance.spacingSmall
                password: !(root.flow?.responseVisible ?? false)
                placeholder: (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
                enabled: !root.waiting
                opacity: root.waiting ? 0.6 : 1
                onAccepted: root.submit()
                Component.onCompleted: focusInput()
            }

            // PAM's own words: "Authentication failed", fingerprint hints and the like
            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                visible: text !== ""
                text: root.flow?.supplementaryMessage ?? ""
                color: root.flow?.supplementaryIsError ? Theme.critical : Theme.surfaceVariantText
                font.pixelSize: Appearance.fontSizeSmall
                wrapMode: Text.Wrap
                elide: Text.ElideNone
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Appearance.spacingSmall
                spacing: Appearance.spacing

                Spinner {
                    visible: root.waiting
                    running: root.waiting
                }

                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: "Cancel"
                    onClicked: Polkit.cancel()
                }

                Button {
                    text: "Authenticate"
                    filled: true
                    enabled: !root.waiting && field.text !== ""
                    onClicked: root.submit()
                }
            }
        }
    }
}
