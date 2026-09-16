import QtQuick
import qs.common

// A glyph centered by its visible shape, not its font box. Nerd Font glyph boxes are
// uneven, so a plain centered Text leaves many icons visibly off-center.
Item {
    id: root

    property string text
    property color color: Theme.surfaceText
    property real size: Appearance.iconSize

    implicitWidth: Math.ceil(Math.max(size, metrics.tightBoundingRect.width))
    implicitHeight: Math.ceil(Math.max(size, metrics.tightBoundingRect.height))

    TextMetrics {
        id: metrics

        font: glyph.font
        text: root.text
    }

    Text {
        id: glyph

        x: Math.round((root.width - metrics.tightBoundingRect.width) / 2 - metrics.tightBoundingRect.x)
        y: Math.round((root.height - metrics.tightBoundingRect.height) / 2 - metrics.tightBoundingRect.y - baselineOffset)
        text: root.text
        color: root.color
        font.family: Appearance.iconFamily
        font.pixelSize: root.size

        Behavior on color {
            CAnim {
                duration: Appearance.animFast
            }
        }
    }
}
