import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services

// The launcher, in place of `rofi -show drun` and `rofi -show calc`. One window, two
// modes: a ranked app list, or a qalc result. Keys follow the rofi config it replaces —
// Ctrl+j / Ctrl+k and the arrows to move, Return to accept, Escape to close.
PanelWindow {
    id: root

    property real progress: 0
    property int selected: 0

    readonly property bool calc: Launcher.mode === "calc"
    readonly property int rowHeight: 52

    visible: Launcher.open || progress > 0
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "qs-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Launcher.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Plain 0, bound once built: a Behavior never runs on a binding's first evaluation,
    // so binding it inline would have the panel appear already settled
    Component.onCompleted: progress = Qt.binding(() => Launcher.open ? 1 : 0)

    Behavior on progress {
        Anim {
            duration: Launcher.open ? Appearance.animSlow : Appearance.animNormal
            easing.bezierCurve: Launcher.open ? Appearance.curveEmphasized : Appearance.curveStandard
        }
    }

    function move(delta: int): void {
        const count = Launcher.results.length;
        if (count === 0) {
            selected = 0;
            return;
        }
        // Wraps, like rofi's `cycle: true`
        selected = (selected + delta + count) % count;
        list.positionViewAtIndex(selected, ListView.Contain);
    }

    function accept(): void {
        if (root.calc) {
            // Nothing to launch — the answer is the result. Enter copies it, which is
            // what the rofi calc modi did.
            if (Launcher.calcResult !== "")
                Launcher.copyResult();
            return;
        }
        Launcher.launch(Launcher.results[selected]);
    }

    // A fresh ranking always re-selects the top hit: the old index pointed into a list
    // that no longer exists
    Connections {
        target: Launcher

        function onResultsChanged(): void {
            root.selected = 0;
            list.positionViewAtIndex(0, ListView.Beginning);
        }
    }

    // No scrim: the desktop stays as it is behind the panel. This is only here to catch
    // a click outside, so it draws nothing.
    MouseArea {
        anchors.fill: parent
        onClicked: Launcher.close()
    }

    FocusScope {
        id: keyboard

        anchors.fill: parent
        focus: true

        // Navigation lives on the scope so it still arrives while the input has focus:
        // the field takes the letters, these bubble up past it
        Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key === Qt.Key_Escape) {
                Launcher.close();
            } else if (ctrl && event.key === Qt.Key_J) {
                root.move(1);
            } else if (ctrl && event.key === Qt.Key_K) {
                root.move(-1);
            } else if (ctrl && event.key === Qt.Key_M) {
                root.accept();
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                root.move(1);
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                root.move(-1);
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.accept();
            } else {
                return;
            }
            event.accepted = true;
        }

        Rectangle {
            id: panel

            anchors.centerIn: parent
            width: Math.min(parent.width - 48, 680)
            // Grows with the list up to eight rows, the way the rofi it replaces did,
            // rather than leaving a tall empty box under two results
            implicitHeight: header.implicitHeight + body.implicitHeight + Appearance.spacingLarge * 3
            height: Math.min(parent.height - 48, implicitHeight)
            radius: Appearance.radiusPanel
            color: Theme.panel
            border.width: 1
            border.color: Qt.alpha(Theme.outlineVariant, 0.7)
            opacity: root.progress
            // Rises a little as it fades in
            scale: 0.96 + 0.04 * root.progress
            clip: true

            Behavior on implicitHeight {
                Anim {
                    duration: Appearance.animNormal
                    easing.bezierCurve: Appearance.curveEmphasized
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Appearance.spacingLarge
                spacing: Appearance.spacingLarge

                // Search field, with the mode's own glyph in it
                Rectangle {
                    id: header

                    Layout.fillWidth: true
                    implicitHeight: 46
                    radius: height / 2
                    color: Qt.alpha(Theme.surfaceContainerHighest, 0.8)
                    border.width: 1
                    border.color: keyboard.activeFocus ? Qt.alpha(Theme.primary, 0.6) : "transparent"

                    Behavior on border.color {
                        CAnim {
                            duration: Appearance.animFast
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Appearance.spacingLarge + 2
                        anchors.rightMargin: Appearance.spacingLarge
                        spacing: Appearance.spacing + 2

                        Icon {
                            text: root.calc ? Icons.calc : Icons.search
                            size: 19
                            color: Theme.primary
                        }

                        TextInput {
                            id: input

                            Layout.fillWidth: true
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.surfaceText
                            selectionColor: Qt.alpha(Theme.primary, 0.4)
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSize + 2
                            focus: true
                            text: Launcher.query
                            onTextChanged: Launcher.query = text

                            // Ctrl+K is TextInput's own "delete to end of line", so it
                            // never reached the navigation on the scope
                            Keys.onPressed: event => {
                                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_K) {
                                    root.move(-1);
                                    event.accepted = true;
                                }
                            }

                            // The window is built on open, so this runs at the right moment
                            Component.onCompleted: forceActiveFocus()

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: input.text === ""
                                text: root.calc ? "Expression…" : "Search apps…"
                                color: Theme.textDim
                                font.pixelSize: input.font.pixelSize
                            }
                        }

                        // Says which mode you are in without a second row to read
                        Rectangle {
                            implicitWidth: modeLabel.implicitWidth + 18
                            implicitHeight: 24
                            radius: height / 2
                            color: Qt.alpha(Theme.primary, 0.16)

                            StyledText {
                                id: modeLabel

                                anchors.centerIn: parent
                                text: root.calc ? "calc" : `${Launcher.results.length}`
                                color: Theme.primary
                                font.pixelSize: Appearance.fontSizeSmall
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }

                Item {
                    id: body

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    implicitHeight: root.calc ? 120 : Math.max(root.rowHeight, Math.min(8, Launcher.results.length) * root.rowHeight)

                    // Apps
                    ListView {
                        id: list

                        anchors.fill: parent
                        visible: !root.calc
                        model: Launcher.results
                        clip: true
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds
                        currentIndex: root.selected

                        delegate: AppRow {
                            required property var modelData
                            required property int index

                            width: list.width
                            height: root.rowHeight
                            entry: modelData
                            selected: index === root.selected
                            onRequestSelect: root.selected = index
                            onActivated: Launcher.launch(modelData)
                        }
                    }

                    // Nothing matched. Kept out of the list so an empty model doesn't
                    // just leave a blank box.
                    StyledText {
                        anchors.centerIn: parent
                        visible: !root.calc && Launcher.results.length === 0
                        text: Launcher.query === "" ? "No applications found" : `Nothing matches “${Launcher.query}”`
                        color: Theme.textDim
                    }

                    // Calculator
                    ColumnLayout {
                        anchors.fill: parent
                        visible: root.calc
                        spacing: Appearance.spacing

                        Item {
                            Layout.fillHeight: true
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: Launcher.calcResult !== "" ? Launcher.calcResult : Launcher.query === "" ? "" : "…"
                            color: Theme.surfaceText
                            font.pixelSize: Appearance.fontSize + 16
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        StyledText {
                            Layout.fillWidth: true
                            visible: Launcher.calcError !== ""
                            text: Launcher.calcError
                            color: Theme.critical
                            font.pixelSize: Appearance.fontSizeSmall
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }
                }

                // What the keys do, so the bindings aren't something you have to know
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacingLarge

                    StyledText {
                        text: root.calc ? "↵ copy" : "↵ launch"
                        color: Theme.textDim
                        font.pixelSize: Appearance.fontSizeSmall
                    }

                    StyledText {
                        visible: !root.calc
                        text: "^j / ^k move"
                        color: Theme.textDim
                        font.pixelSize: Appearance.fontSizeSmall
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    StyledText {
                        text: "esc close"
                        color: Theme.textDim
                        font.pixelSize: Appearance.fontSizeSmall
                    }
                }
            }
        }
    }
}
