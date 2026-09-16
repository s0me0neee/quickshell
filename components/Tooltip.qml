import QtQuick
import Quickshell
import qs.common

// Small glass label under an item. Appears after a short hover delay and takes no input.
PopupWindow {
    id: root

    required property Item target
    property string text
    property bool show: false

    property bool shown: false
    property real progress: shown ? 1 : 0
    readonly property int gap: 8

    onShowChanged: {
        if (show) {
            delay.restart();
        } else {
            delay.stop();
            shown = false;
        }
    }

    anchor.item: target
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.Slide
    visible: shown || progress > 0
    color: "transparent"
    implicitWidth: label.implicitWidth + 22
    implicitHeight: label.implicitHeight + 12 + gap

    Behavior on progress {
        Anim {
            duration: Appearance.animFast
        }
    }

    Timer {
        id: delay

        interval: 450
        onTriggered: root.shown = root.text !== ""
    }

    Rectangle {
        y: root.gap - 4 * (1 - root.progress)
        width: parent.width
        height: parent.height - root.gap
        radius: Math.min(height / 2, 12)
        color: Theme.panel
        border.width: 1
        border.color: Theme.glassEdge
        opacity: root.progress

        StyledText {
            id: label

            anchors.centerIn: parent
            text: root.text
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: Appearance.fontSizeSmall
        }
    }
}
