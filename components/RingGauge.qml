import QtQuick
import qs.common

// Circular progress ring, 0..1. Repaints only when the value or colors change.
Canvas {
    id: root

    property real value: 0
    property real lineWidth: 2.2
    property color color: Theme.primary
    property color trackColor: Qt.alpha(Theme.surfaceText, 0.15)

    onValueChanged: requestPaint()
    onColorChanged: requestPaint()
    onTrackColorChanged: requestPaint()
    onWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const r = Math.min(width, height) / 2 - lineWidth / 2;
        ctx.lineWidth = lineWidth;
        ctx.lineCap = "round";

        ctx.strokeStyle = Theme.css(trackColor);
        ctx.beginPath();
        ctx.arc(width / 2, height / 2, r, 0, 2 * Math.PI);
        ctx.stroke();

        const v = Math.max(0, Math.min(1, value));
        if (v > 0) {
            ctx.strokeStyle = Theme.css(root.color);
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + v * 2 * Math.PI);
            ctx.stroke();
        }
    }
}
