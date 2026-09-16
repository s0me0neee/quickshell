import QtQuick
import qs.common

// Tabs with an underline that stretches toward the one you picked, then contracts
// behind it, so the bar reaches the new tab before it lets go of the old.
//
// The trick is two numbers chasing the same index at different speeds: whichever is
// ahead is the indicator's leading edge. Nothing here knows which direction it moved.
Item {
    id: root

    // [{ icon, label }]
    property var model: []
    property int current: 0

    signal selected(int index)

    readonly property real tabWidth: model.length > 0 ? width / model.length : width
    // Inset so the bar reads as under the label rather than as a table rule
    readonly property real inset: 10

    property real leading: current
    property real trailing: current

    implicitHeight: 40

    Behavior on leading {
        Anim {
            duration: Appearance.animFast
        }
    }

    Behavior on trailing {
        Anim {
            duration: Appearance.animNormal
            easing.bezierCurve: Appearance.curveEmphasized
        }
    }

    Row {
        anchors.fill: parent

        Repeater {
            model: root.model

            MouseArea {
                id: tab

                required property int index
                required property var modelData
                readonly property bool active: root.current === index

                width: root.tabWidth
                height: root.height
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selected(index)

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    anchors.bottomMargin: 4
                    radius: Appearance.radiusItem
                    color: !tab.active && tab.containsMouse ? Qt.alpha(Theme.surfaceText, 0.07) : "transparent"

                    Behavior on color {
                        CAnim {
                            duration: Appearance.animFast
                        }
                    }
                }

                Row {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -2
                    spacing: Appearance.spacingSmall + 1

                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tab.modelData.icon
                        size: 16
                        color: tab.active ? Theme.primary : Theme.surfaceVariantText
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: tab.modelData.label
                        color: tab.active ? Theme.surfaceText : Theme.surfaceVariantText
                        font.pixelSize: Appearance.fontSizeSmall
                        font.weight: tab.active ? Font.DemiBold : Font.Normal
                    }
                }
            }
        }
    }

    // The rule the indicator slides along
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Qt.alpha(Theme.outlineVariant, 0.5)
    }

    Rectangle {
        readonly property real first: Math.min(root.leading, root.trailing)
        readonly property real last: Math.max(root.leading, root.trailing)

        x: first * root.tabWidth + root.inset
        anchors.bottom: parent.bottom
        width: (last + 1) * root.tabWidth - root.inset - x
        height: 3
        topLeftRadius: height
        topRightRadius: height
        color: Theme.primary
    }
}
