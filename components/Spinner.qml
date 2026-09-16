import QtQuick
import qs.common

// Rotating arc. Only animates while visible and running (e.g. while a network connects).
Item {
    id: root

    property bool running: true
    property color color: Theme.primary
    property real size: 14

    implicitWidth: size
    implicitHeight: size

    Canvas {
        id: arc

        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = root.color;
            ctx.lineWidth = 2;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, width / 2 - 1.5, 0, Math.PI * 1.4);
            ctx.stroke();
        }

        Connections {
            target: root

            function onColorChanged(): void {
                arc.requestPaint();
            }
        }

        RotationAnimator on rotation {
            from: 0
            to: 360
            duration: 900
            loops: Animation.Infinite
            running: root.running && root.visible
        }
    }
}
