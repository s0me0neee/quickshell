import QtQuick
import qs.common
import qs.components

// A row of two or three mutually exclusive options, the picked one filled. Smaller than
// the control center's profile chips, because a settings row has less height to give.
Row {
    id: root

    property var options: []
    property int current: 0

    signal picked(int index)

    spacing: 2

    Repeater {
        model: root.options

        MouseArea {
            id: option

            required property int index
            required property string modelData
            readonly property bool active: root.current === index

            implicitWidth: Math.max(46, label.implicitWidth + Appearance.spacingLarge * 2)
            implicitHeight: 30
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: root.picked(index)

            Rectangle {
                anchors.fill: parent
                // Square shoulders where two options meet, rounded at the ends, so the
                // group reads as one control rather than separate buttons
                topLeftRadius: option.index === 0 ? height / 2 : 4
                bottomLeftRadius: topLeftRadius
                topRightRadius: option.index === root.options.length - 1 ? height / 2 : 4
                bottomRightRadius: topRightRadius
                color: option.active ? Theme.accent : option.containsMouse ? Qt.alpha(Theme.surfaceText, 0.1) : Qt.alpha(Theme.secondaryContainer, 0.4)

                Behavior on color {
                    CAnim {
                        duration: Appearance.animFast
                    }
                }
            }

            StyledText {
                id: label

                anchors.centerIn: parent
                text: option.modelData
                color: option.active ? Theme.primaryContainerText : Theme.surfaceVariantText
                font.pixelSize: Appearance.fontSizeSmall
                font.weight: option.active ? Font.DemiBold : Font.Normal
            }
        }
    }
}
