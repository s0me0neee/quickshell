import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services

// One notification: app icon or image, summary, body and its actions. Left click runs
// the default action if the app offers one, otherwise it just dismisses. Right or
// middle click throws it away.
Rectangle {
    id: root

    required property NotifEntry entry
    // Popups dismiss on click; in the list there is nothing left to dismiss
    property bool inList: false
    // Off inside a group, where the header above already names the app
    property bool showAppName: true

    readonly property var defaultAction: entry.actions.find(a => a.identifier === "default") ?? null
    readonly property var buttons: entry.actions.filter(a => a.identifier !== "default")
    readonly property string appIconPath: entry.appIcon === "" ? "" : Quickshell.iconPath(entry.appIcon, true)

    implicitHeight: layout.implicitHeight + Appearance.spacingLarge * 2
    radius: Appearance.radiusPanel
    color: mouse.containsMouse ? Qt.alpha(Theme.surfaceContainerHigh, 0.85) : Theme.panel
    border.width: 1
    border.color: entry.critical ? Qt.alpha(Theme.critical, 0.5) : Theme.glassEdge

    Behavior on color {
        CAnim {
            duration: Appearance.animFast
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: event => {
            if (event.button === Qt.LeftButton) {
                if (root.defaultAction)
                    root.defaultAction.invoke();
                else if (!root.inList)
                    root.entry.dismiss();
            } else {
                root.entry.close();
            }
        }
    }

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Appearance.spacingLarge
        spacing: Appearance.spacingLarge

        ClippingRectangle {
            Layout.alignment: Qt.AlignTop
            implicitWidth: 38
            implicitHeight: 38
            radius: width / 2
            color: root.entry.critical ? Qt.alpha(Theme.critical, 0.2) : Qt.alpha(Theme.primary, 0.18)

            Image {
                anchors.fill: parent
                visible: root.entry.image !== ""
                source: root.entry.image
                sourceSize.width: 76
                sourceSize.height: 76
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            IconImage {
                anchors.centerIn: parent
                visible: root.entry.image === "" && root.appIconPath !== ""
                implicitSize: Appearance.themeIconSize
                asynchronous: true
                source: root.appIconPath
            }

            Icon {
                anchors.centerIn: parent
                visible: root.entry.image === "" && root.appIconPath === ""
                text: Icons.notifications["notification"]
                size: 18
                color: root.entry.critical ? Theme.critical : Theme.primary
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing

                StyledText {
                    Layout.fillWidth: true
                    visible: root.showAppName
                    text: root.entry.appName
                    color: root.entry.critical ? Theme.critical : Theme.surfaceVariantText
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.DemiBold
                }

                // Keeps the close button hard right once the name above is gone
                Item {
                    Layout.fillWidth: true
                    visible: !root.showAppName
                }

                CircleButton {
                    id: closeButton

                    implicitWidth: 20
                    implicitHeight: 20
                    icon: Icons.close
                    iconSize: 11
                    fill: "transparent"
                    iconColor: Theme.surfaceVariantText
                    // Its own hover counts too: this button sits above the card's MouseArea
                    // and takes the hover events, so pointing at it cleared containsMouse
                    // on the card and faded the button out from under the pointer
                    opacity: mouse.containsMouse || closeButton.containsMouse ? 1 : 0
                    onClicked: root.entry.close()

                    Behavior on opacity {
                        Anim {
                            duration: Appearance.animFast
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                text: root.entry.summary
                wrapMode: Text.Wrap
                maximumLineCount: 2
                font.pixelSize: Appearance.fontSize
                font.weight: Font.Bold
            }

            StyledText {
                Layout.fillWidth: true
                visible: text !== ""
                // Notification bodies may carry basic markup
                text: root.entry.body
                textFormat: Text.StyledText
                color: Theme.surfaceVariantText
                wrapMode: Text.Wrap
                maximumLineCount: 4
                font.pixelSize: Appearance.fontSizeSmall + 1
            }

            RowLayout {
                Layout.topMargin: Appearance.spacingSmall
                visible: root.buttons.length > 0
                spacing: Appearance.spacing

                Repeater {
                    model: root.buttons

                    Button {
                        required property var modelData

                        text: modelData.text
                        onClicked: {
                            modelData.invoke();
                            if (!root.inList)
                                root.entry.dismiss();
                        }
                    }
                }
            }
        }
    }
}
