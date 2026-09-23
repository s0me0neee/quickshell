import QtQuick
import qs.common

// The translucent tint that says a surface is being interacted with. One layer for
// hover, press, focus and active, so every pressable thing in the shell gives the same
// feedback instead of each widget inventing its own hover colour.
//
// Fills its parent, so it goes inside the shape it tints and *before* the content, or
// it paints over the label. Set `radius` to the parent's: it can't be read from here
// because a plain Item has no radius to read.
Rectangle {
    id: root

    property bool hovered: false
    property bool pressed: false
    property bool focused: false
    property bool active: false

    // What the tint is made of — normally the surface's content colour
    property color tone: Theme.surfaceText

    anchors.fill: parent
    radius: 0
    color: tone
    opacity: {
        if (!enabled)
            return 0;
        if (pressed)
            return Appearance.statePress;
        if (active)
            return hovered ? Appearance.stateActive + Appearance.stateHover : Appearance.stateActive;
        if (hovered)
            return Appearance.stateHover;
        if (focused)
            return Appearance.stateFocus;
        return 0;
    }

    Behavior on opacity {
        Anim {
            duration: Appearance.animFast
        }
    }
}
