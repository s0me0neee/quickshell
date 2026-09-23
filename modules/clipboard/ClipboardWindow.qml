import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

PanelWindow {
    id: root

    property real progress: 0
    property int selected: 0

    visible: Clipboard.open || progress > 0
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "qs-clipboard"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Clipboard.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Component.onCompleted: progress = Qt.binding(() => Clipboard.open ? 1 : 0)

    function inspectSelected(): void {
        const entry = Clipboard.filteredEntries[selected];
        // Only images have a pane to fill; decoding text rows would be wasted processes
        if (entry?.isImage)
            Clipboard.inspect(entry);
        else
            Clipboard.clearInspection();
    }

    onSelectedChanged: inspectSelected()

    Connections {
        target: Clipboard

        // Loading the list does not change `selected` when it is already zero, so
        // explicitly inspect the first fresh entry rather than waiting for a key press.
        function onEntriesChanged(): void {
            root.selected = 0;
            root.inspectSelected();
        }
    }

    function move(delta: int): void {
        const count = Clipboard.filteredEntries.length;
        if (count === 0) {
            selected = 0;
            return;
        }
        selected = (selected + delta + count) % count;
        // Only the keyboard scrolls the list to the selection. Hover selects too, and
        // doing it there dragged the view back under every row a touchpad scroll crossed
        history.positionViewAtIndex(selected, ListView.Contain);
    }

    Behavior on progress {
        Anim {
            duration: Clipboard.open ? Appearance.animSlow : Appearance.animNormal
            easing.bezierCurve: Clipboard.open ? Appearance.curveEmphasized : Appearance.curveStandard
        }
    }

    // No scrim: the desktop stays as it is behind the panel. This is only here to catch
    // a click outside, so it draws nothing.
    MouseArea {
        anchors.fill: parent
        onClicked: Clipboard.closeHistory()
    }

    Shortcut {
        sequences: ["Escape"]
        context: Qt.WindowShortcut
        onActivated: Clipboard.closeHistory()
    }

    FocusScope {
        id: keyboard

        anchors.fill: parent
        focus: true

        // Navigation sits on the scope so the keys still arrive while the search box
        // has focus: the input takes the letters, these bubble up to here
        Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key === Qt.Key_Escape) {
                Clipboard.closeHistory();
            } else if (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_Return)) {
                root.move(1);
            } else if (ctrl && event.key === Qt.Key_K) {
                root.move(-1);
            } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                root.move(1);
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                root.move(-1);
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                const entry = Clipboard.filteredEntries[root.selected];
                if (entry)
                    Clipboard.paste(entry);
            } else {
                return;
            }
            event.accepted = true;
        }

        Rectangle {
            id: panel

            anchors.centerIn: parent
            width: Math.min(parent.width - 48, 920)
            height: Math.min(parent.height - 48, 620)
            radius: Appearance.radiusPanel
            color: Theme.panel
            border.width: 1
            border.color: Qt.alpha(Theme.outlineVariant, 0.7)
            opacity: root.progress
            scale: 0.96 + 0.04 * root.progress
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.margins: Appearance.spacingLarge
                spacing: Appearance.spacingLarge

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Appearance.spacing

                    RowLayout {
                        Layout.fillWidth: true

                        StyledText {
                            text: "Clipboard history"
                            font.weight: Font.Bold
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: `${Clipboard.filteredEntries.length} items`
                            color: Theme.textDim
                            horizontalAlignment: Text.AlignRight
                        }

                        CircleButton {
                            icon: Icons.clearAll
                            iconSize: 14
                            enabled: Clipboard.entries.length > 0
                            opacity: enabled ? 1 : 0.4
                            tooltip: "Clear all history"
                            onClicked: Clipboard.clearAll()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 36
                        radius: Appearance.radiusItem
                        color: Qt.alpha(Theme.surfaceContainerHighest, 0.8)
                        border.width: keyboard.activeFocus ? 1 : 0
                        border.color: Theme.primary

                        TextInput {
                            id: search

                            anchors.fill: parent
                            anchors.leftMargin: Appearance.spacingLarge
                            anchors.rightMargin: Appearance.spacingLarge
                            verticalAlignment: TextInput.AlignVCenter
                            color: Theme.surfaceText
                            selectionColor: Qt.alpha(Theme.primary, 0.4)
                            font.family: Appearance.fontFamily
                            font.pixelSize: Appearance.fontSize
                            focus: true
                            text: Clipboard.query
                            Component.onCompleted: forceActiveFocus()
                            // Caught before TextInput sees it: Ctrl+K is its "delete to end of
                            // line", so it never bubbled up to the navigation on the scope
                            Keys.onPressed: event => {
                                if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_K) {
                                    root.move(-1);
                                    event.accepted = true;
                                }
                            }
                            onTextChanged: {
                                Clipboard.query = text;
                                root.selected = 0;
                                root.inspectSelected();
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: search.text === ""
                                text: "Search clipboard"
                                color: Theme.textDim
                            }
                        }
                    }

                    ListView {
                        id: history

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: Appearance.spacingSmall
                        model: Clipboard.filteredEntries

                        WheelScroll {
                            view: history
                        }

                        delegate: ListItem {
                            required property var modelData
                            // Without this the delegate's `index` is undefined, so the
                            // selection comparison never matched and nothing highlighted
                            required property int index

                            width: history.width
                            label: modelData.preview
                            subtitle: modelData.id
                            icon: ""
                            highlighted: index === root.selected
                            onActivated: Clipboard.paste(modelData)
                            onContainsMouseChanged: if (containsMouse) root.selected = index

                            CircleButton {
                                icon: Icons.close
                                iconSize: 13
                                fill: "transparent"
                                iconColor: Theme.textDim
                                tooltip: "Delete"
                                onClicked: Clipboard.deleteEntry(modelData)
                            }
                        }
                    }
                }

                Rectangle {
                    // Text rows already show their text in the list; only images earn a pane
                    visible: Clipboard.filteredEntries[root.selected]?.isImage ?? false
                    Layout.fillHeight: true
                    Layout.preferredWidth: 330
                    radius: Appearance.radiusItem
                    color: Qt.alpha(Theme.surfaceContainerHighest, 0.55)
                    clip: true

                    Image {
                        anchors.fill: parent
                        anchors.margins: Appearance.spacing
                        visible: Clipboard.previewPath !== "" && Clipboard.previewMime.startsWith("image/")
                        // Versioned so Qt reloads it, and sourceSize so a 4K screenshot
                        // is decoded at the size it will actually be drawn
                        source: Clipboard.previewPath === "" ? "" : `file://${Clipboard.previewPath}?v=${Clipboard.previewVersion}`
                        sourceSize.width: 660
                        sourceSize.height: 560
                        fillMode: Image.PreserveAspectFit
                        asynchronous: true
                        cache: false
                    }

                    StyledText {
                        anchors.fill: parent
                        anchors.margins: Appearance.spacingLarge
                        visible: Clipboard.previewPath === "" || !Clipboard.previewMime.startsWith("image/")
                        text: Clipboard.filteredEntries[root.selected]?.preview ?? "Select an item"
                        color: Theme.surfaceText
                        wrapMode: Text.Wrap
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}
