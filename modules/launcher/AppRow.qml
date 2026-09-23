import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.components

// One application in the launcher list: themed icon, name, and whatever subtitle the
// desktop entry offers.
MouseArea {
    id: root

    required property var entry
    property bool selected: false

    signal activated
    signal requestSelect

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: activated()
    onContainsMouseChanged: {
        if (containsMouse)
            requestSelect();
    }

    Rectangle {
        anchors.fill: parent
        anchors.rightMargin: 2
        radius: Appearance.radiusItem + 4
        color: root.selected ? Qt.alpha(Theme.primary, 0.16) : "transparent"

        Behavior on color {
            CAnim {
                duration: Appearance.animFast
            }
        }

        StateLayer {
            radius: parent.radius
            tone: root.selected ? Theme.primary : Theme.surfaceText
            hovered: root.containsMouse
            pressed: root.pressed
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Appearance.spacing + 4
            anchors.rightMargin: Appearance.spacingLarge
            spacing: Appearance.spacing + 4

            IconImage {
                // A theme ships artwork at set sizes; asking for one it doesn't have
                // makes Qt rescale the nearest and the row looks smeared
                implicitSize: 32
                source: Quickshell.iconPath(root.entry?.icon ?? "", "application-x-executable")
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: root.entry?.name ?? ""
                    color: Theme.surfaceText
                    font.pixelSize: Appearance.fontSize
                    font.weight: root.selected ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }

                StyledText {
                    readonly property string sub: root.entry?.genericName || root.entry?.comment || ""

                    Layout.fillWidth: true
                    visible: sub !== ""
                    text: sub
                    color: Theme.textDim
                    font.pixelSize: Appearance.fontSizeSmall
                    elide: Text.ElideRight
                }
            }

            // Only on the row you would hit with Return, so the list isn't a column of
            // repeated arrows
            Icon {
                visible: root.selected
                text: Icons.enterKey
                size: 14
                color: Theme.primary
            }
        }
    }
}
