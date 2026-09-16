import QtQuick
import qs.common

// A glyph centered by its visible shape, not its font box. Nerd Font glyph boxes are
// uneven, so a plain centered Text leaves many icons visibly off-center.
//
// The position is worked out from font metrics alone, never from the Text item's own
// baselineOffset: that is only meaningful once the item has been laid out, so bindings
// using it settled at different moments and left each icon off by its own pixel or two
// in its own direction.
Item {
    id: root

    property string text
    property color color: Theme.surfaceText
    property real size: Appearance.iconSize

    // Hand alignment, in pixels, for the glyphs the ink box doesn't settle where the eye
    // wants it — a speaker with a wave on one side reads left of centre even when its
    // box is dead centre. Positive nudgeX moves right, positive nudgeY moves down.
    property real nudgeX: 0
    property real nudgeY: 0

    // Rounded up to an even number, so centering this inside an even-sized button
    // lands on a whole pixel instead of splitting one
    implicitWidth: 2 * Math.ceil(Math.max(size, metrics.tightBoundingRect.width) / 2)
    implicitHeight: 2 * Math.ceil(Math.max(size, metrics.tightBoundingRect.height) / 2)

    FontMetrics {
        id: fm

        font: glyph.font
    }

    TextMetrics {
        id: metrics

        font: glyph.font
        text: root.text
    }

    Text {
        id: glyph

        // Ink sits (ascent + tightBoundingRect.y) below the item's top when drawn at
        // y = 0; both of those are baseline-relative, so this puts the ink box dead
        // center whatever shape the glyph happens to be
        x: Math.round((root.width - metrics.tightBoundingRect.width) / 2 - metrics.tightBoundingRect.x + root.nudgeX)
        y: Math.round((root.height - metrics.tightBoundingRect.height) / 2 - fm.ascent - metrics.tightBoundingRect.y + root.nudgeY)
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
