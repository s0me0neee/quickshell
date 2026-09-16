import QtQuick
import qs.common

// A Material Symbol. Every glyph is drawn on the same square grid, so centering the
// text box centers the icon — that is the whole reason for the font. The Nerd Font
// glyphs this replaced sat on boxes of their own and needed per-glyph ink compensation
// to look straight, which is what made them drift a pixel or two each.
Item {
    id: root

    property string text
    property color color: Theme.surfaceText
    property real size: Appearance.iconSize
    // 0 draws the outline, 1 the solid version
    property real fill: 0
    // Native rendering snaps to the pixel grid, which is what keeps small bar icons
    // crisp. Anything that scales wants the distance-field renderer instead.
    property bool crisp: true

    // Qt builds a new face of a variable font for every distinct pixel size and optical
    // size it sees, and this one is 14 MB. Keeping both on a small, stable set means an
    // animation can never spawn thousands of them — animate `scale`, not `size`.
    readonly property int pixelSize: Math.max(1, Math.round(size))
    readonly property int opticalSize: pixelSize <= 20 ? 20 : pixelSize <= 28 ? 24 : pixelSize <= 44 ? 40 : 48

    implicitWidth: size
    implicitHeight: size

    Text {
        anchors.fill: parent
        text: root.text
        color: root.color
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        renderType: root.crisp ? Text.NativeRendering : Text.QtRendering
        font.family: Appearance.iconFamily
        font.pixelSize: root.pixelSize
        font.variableAxes: ({
            "FILL": root.fill,
            "opsz": root.opticalSize
        })

        Behavior on color {
            CAnim {
                duration: Appearance.animFast
            }
        }
    }
}
