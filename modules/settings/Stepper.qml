import QtQuick
import qs.common
import qs.components

// − value + for a number.
//
// A stepper rather than a slider: every one of these is a small integer where the exact
// value matters, and a 140px slider cannot reliably hit 14 rather than 15. Scrolling
// anywhere on it works too.
Row {
    id: root

    property real value: 0
    property real from: 0
    property real to: 100
    property real step: 1
    // What the middle reads, when the raw number isn't what you mean
    property var format: value => `${value}`

    signal moved(real value)

    function nudge(delta: real): void {
        const next = Math.max(from, Math.min(to, value + delta * step));
        if (next !== value)
            moved(next);
    }

    spacing: Appearance.spacingSmall

    CircleButton {
        implicitWidth: 28
        implicitHeight: 28
        icon: Icons.chevronLeft
        iconSize: 15
        enabled: root.value > root.from
        opacity: enabled ? 1 : 0.35
        onClicked: root.nudge(-1)
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        // Wide enough for the longest reading, so stepping never shifts the buttons
        width: 52
        horizontalAlignment: Text.AlignHCenter
        text: root.format(root.value)
        font.weight: Font.DemiBold

        MouseArea {
            anchors.fill: parent
            onWheel: event => root.nudge(event.angleDelta.y > 0 ? 1 : -1)
        }
    }

    CircleButton {
        implicitWidth: 28
        implicitHeight: 28
        icon: Icons.chevronRight
        iconSize: 15
        enabled: root.value < root.to
        opacity: enabled ? 1 : 0.35
        onClicked: root.nudge(1)
    }
}
