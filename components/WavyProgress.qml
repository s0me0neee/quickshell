import QtQuick
import qs.common

// Progress line: the played part waves while `wavy`, the rest is a flat track.
// Repaints only when the value changes (about once a second for media).
Canvas {
    id: root

    property real value: 0
    property bool wavy: true
    property real lineWidth: 4
    property color color: Theme.primary
    property color trackColor: Qt.alpha(Theme.surfaceText, 0.18)

    implicitHeight: 14

    onValueChanged: requestPaint()
    onWavyChanged: requestPaint()
    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const cy = height / 2;
        const start = lineWidth / 2;
        const end = width - lineWidth / 2;
        const split = start + (end - start) * Math.max(0, Math.min(1, value));
        ctx.lineWidth = lineWidth;
        ctx.lineCap = "round";

        if (split > start) {
            ctx.strokeStyle = Theme.css(root.color);
            ctx.beginPath();
            for (let x = start; x <= split; x += 1) {
                const y = cy + (wavy ? 2.5 * Math.sin(2 * Math.PI * x / 22) : 0);
                if (x === start)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            ctx.stroke();
        }

        const gap = split > start ? 7 : 0;
        if (split + gap < end) {
            ctx.strokeStyle = Theme.css(trackColor);
            ctx.beginPath();
            ctx.moveTo(split + gap, cy);
            ctx.lineTo(end, cy);
            ctx.stroke();
        }
    }
}
