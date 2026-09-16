import QtQuick
import qs.common

// Thick pill slider with the icon inside the fill and the value on the right.
// Emits moved(); `value` (0..1) is only set from outside.
Item {
    id: root

    property real value: 0
    property string icon
    property bool muted: false
    readonly property real shown: area.pressed ? area.dragValue : value
    property string label: `${Math.round(shown * 100)}%`

    signal moved(real value)

    implicitWidth: 260
    implicitHeight: 34

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: Qt.alpha(Theme.secondaryContainer, 0.6)
    }

    Rectangle {
        id: fill

        width: Math.max(height, parent.width * Math.min(1, root.shown))
        height: parent.height
        radius: height / 2
        color: root.muted ? Qt.alpha(Theme.critical, 0.7) : Theme.primary

        Behavior on width {
            enabled: !area.pressed

            Anim {
                duration: Appearance.animFast
            }
        }

        Behavior on color {
            CAnim {
                duration: Appearance.animNormal
            }
        }
    }

    Icon {
        x: (root.height - width) / 2
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        size: 16
        color: Theme.primaryText
    }

    StyledText {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: fill.width > root.width - 48 ? Theme.primaryText : Theme.surfaceText
        font.pixelSize: Appearance.fontSizeSmall + 1
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: area

        property real dragValue: 0

        function update(x: real): void {
            dragValue = Math.max(0, Math.min(1, x / width));
            root.moved(dragValue);
        }

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: event => update(event.x)
        onPositionChanged: event => {
            if (pressed)
                update(event.x);
        }
        onWheel: event => root.moved(Math.max(0, Math.min(1, root.value + (event.angleDelta.y > 0 ? 0.02 : -0.02))))
    }
}
