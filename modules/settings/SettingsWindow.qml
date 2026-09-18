import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.common
import qs.components
import qs.services

// Settings, in Clavis's shape: a navigation rail down the left, one page at a time on
// the right, cards inside a page. Drawn in our own glass, over Hyprland's blur.
//
// Deliberately small. This is not a copy of every token in Appearance.qml — it holds
// what gets changed often and what is a nuisance to change by hand. Everything else
// stays a constant in the source, where it is easier to reason about.
PanelWindow {
    id: root

    // Starts at 0 and is bound once built, the same trick the session menu uses: the
    // LazyLoader only creates this once it is already open, and a Behavior never runs
    // on a binding's first evaluation
    property real progress: 0
    property int page: 0

    readonly property list<var> pages: [
        {
            icon: Icons.palette,
            label: "Appearance"
        },
        {
            icon: Icons.tune,
            label: "Bar"
        },
        {
            icon: Icons.music,
            label: "Media"
        },
        {
            icon: Icons.scale,
            label: "Units"
        }
    ]

    Component.onCompleted: progress = Qt.binding(() => Settings.menuOpen ? 1 : 0)

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "qs-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Settings.menuOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Behavior on progress {
        Anim {
            duration: Settings.menuOpen ? Appearance.animSlow : Appearance.animNormal
            easing.bezierCurve: Settings.menuOpen ? Appearance.curveEmphasized : Appearance.curveStandard
        }
    }

    // Dim over the blur. Clicking it closes, the way clicking outside a popout does
    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Theme.surface, 0.5)
        opacity: root.progress

        MouseArea {
            anchors.fill: parent
            onClicked: Settings.close()
        }
    }

    Shortcut {
        sequences: ["Escape"]
        onActivated: Settings.close()
    }

    Rectangle {
        anchors.centerIn: parent
        width: 660
        height: 460
        radius: Appearance.radiusPanel
        color: Theme.panel
        border.width: 1
        border.color: Qt.alpha(Theme.outlineVariant, 0.6)
        clip: true
        opacity: root.progress
        scale: 0.94 + 0.06 * root.progress

        // Swallows clicks so they don't reach the dimmer behind and close the window
        MouseArea {
            anchors.fill: parent
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // --- navigation rail ---

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 172
                color: Qt.alpha(Theme.surfaceContainer, 0.5)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Appearance.spacing
                    spacing: 2

                    StyledText {
                        Layout.leftMargin: Appearance.spacing
                        Layout.topMargin: Appearance.spacing
                        Layout.bottomMargin: Appearance.spacing
                        text: "Settings"
                        font.pixelSize: Appearance.fontSize + 3
                        font.weight: Font.Bold
                    }

                    Repeater {
                        model: root.pages

                        ListItem {
                            required property int index
                            required property var modelData

                            icon: modelData.icon
                            label: modelData.label
                            highlighted: root.page === index
                            onActivated: root.page = index
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }

                    // Where the file actually is, for anyone who would rather edit it
                    StyledText {
                        Layout.fillWidth: true
                        Layout.leftMargin: Appearance.spacing
                        Layout.bottomMargin: Appearance.spacingSmall
                        text: "~/.local/state/quickshell"
                        color: Theme.textDim
                        elide: Text.ElideMiddle
                        font.pixelSize: Appearance.fontSizeSmall - 1
                    }
                }
            }

            // --- the page ---

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: pageBox.implicitHeight + Appearance.spacingLarge * 2
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Item {
                    id: pageBox

                    x: Appearance.spacingLarge + 4
                    y: Appearance.spacingLarge
                    width: parent.width - (Appearance.spacingLarge + 4) * 2
                    implicitHeight: [appearanceLoader, barLoader, mediaLoader, unitsLoader][root.page]?.item?.implicitHeight ?? 0

                    Loader {
                        id: appearanceLoader

                        width: parent.width
                        active: root.page === 0
                        visible: root.page === 0

                        sourceComponent: Component {
                            AppearancePage {
                                width: appearanceLoader.width
                            }
                        }
                    }

                    Loader {
                        id: barLoader

                        width: parent.width
                        active: root.page === 1
                        visible: root.page === 1

                        sourceComponent: Component {
                            BarPage {
                                width: barLoader.width
                            }
                        }
                    }

                    Loader {
                        id: mediaLoader

                        width: parent.width
                        active: root.page === 2
                        visible: root.page === 2

                        sourceComponent: Component {
                            MediaPage {
                                width: mediaLoader.width
                            }
                        }
                    }

                    Loader {
                        id: unitsLoader

                        width: parent.width
                        active: root.page === 3
                        visible: root.page === 3

                        sourceComponent: Component {
                            UnitsPage {
                                width: unitsLoader.width
                            }
                        }
                    }
                }
            }
        }
    }
}
