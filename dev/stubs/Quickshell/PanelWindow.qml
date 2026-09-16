import QtQuick
import Preview

// A wlr-layer-shell surface. Deliberately not a QML Window: every surface is an Item in
// the one preview window, so the shell behaves like a single ordinary application window.
//
// anchors/margins keep their layer-shell meaning — an anchor pins the surface to that
// edge of the monitor, and opposite anchors together stretch it across.
QtObject {
    id: win

    // Aliased into the surface rather than reparented later, so children have a sized
    // visual parent from the moment they are built and `parent.width` is never null
    default property alias surfaceContent: surfaceItem.data
    readonly property Item contentItem: surfaceItem

    property Anchors anchors: Anchors {}
    property Margins margins: Margins {}
    property int exclusiveZone: 0
    property int exclusionMode: ExclusionMode.Auto
    property var screen: null
    // Input masking isn't emulated; the whole surface takes clicks
    property var mask: null
    property int implicitWidth: 0
    property int implicitHeight: 0
    property bool visible: true
    property color color: "transparent"

    readonly property int width: anchors.left && anchors.right ? Preview.screenWidth - margins.left - margins.right : Math.max(0, implicitWidth)
    readonly property int height: anchors.top && anchors.bottom ? Preview.screenHeight - margins.top - margins.bottom : Math.max(0, implicitHeight)

    readonly property int surfaceX: {
        if (anchors.left && anchors.right)
            return margins.left;
        if (anchors.right)
            return Preview.screenWidth - margins.right - width;
        if (anchors.left)
            return margins.left;
        return Math.round((Preview.screenWidth - width) / 2);
    }
    readonly property int surfaceY: {
        if (anchors.top && anchors.bottom)
            return margins.top;
        if (anchors.bottom)
            return Preview.screenHeight - margins.bottom - height;
        if (anchors.top)
            return margins.top;
        return Math.round((Preview.screenHeight - height) / 2);
    }

    readonly property PreviewSurface layer: PreviewSurface {
        id: surfaceItem

        win: win
    }

    Component.onCompleted: Preview.addSurface(win, surfaceItem)
    Component.onDestruction: Preview.removeSurface(win)
}
