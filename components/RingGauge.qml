import QtQuick
import QtQuick.Shapes
import qs.common

// Circular progress ring, 0..1. A Shape rather than a Canvas: an animated value only
// updates two arcs on the GPU instead of re-rasterising and re-uploading a texture per frame.
Shape {
    id: root

    property real value: 0
    property real lineWidth: 2.2
    property color color: Theme.primary
    property color trackColor: Qt.alpha(Theme.surfaceText, 0.15)

    readonly property real radius: Math.max(0, Math.min(width, height) / 2 - lineWidth / 2)
    readonly property real sweep: Math.max(0, Math.min(1, value)) * 360

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: "transparent"
        strokeColor: root.trackColor
        strokeWidth: root.lineWidth
        capStyle: ShapePath.RoundCap

        PathAngleArc {
            centerX: root.width / 2
            centerY: root.height / 2
            radiusX: root.radius
            radiusY: root.radius
            startAngle: 0
            sweepAngle: 360
        }
    }

    ShapePath {
        fillColor: "transparent"
        // Transparent rather than hidden at 0, so the round cap never draws a lone dot
        strokeColor: root.sweep > 0 ? root.color : "transparent"
        strokeWidth: root.lineWidth
        capStyle: ShapePath.RoundCap

        PathAngleArc {
            centerX: root.width / 2
            centerY: root.height / 2
            radiusX: root.radius
            radiusY: root.radius
            startAngle: -90
            sweepAngle: root.sweep
        }
    }
}
