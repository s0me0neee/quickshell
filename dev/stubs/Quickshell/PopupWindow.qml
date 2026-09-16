import QtQuick
import Preview

// An xdg popup anchored to an item in another surface. Only the placement the shell
// actually asks for is emulated: centred under the anchor item, slid back inside the
// monitor when it would hang off an edge.
QtObject {
    id: win

    default property alias surfaceContent: surfaceItem.data
    readonly property Item contentItem: surfaceItem

    property PopupAnchor anchor: PopupAnchor {}
    property int implicitWidth: 0
    property int implicitHeight: 0
    property bool visible: true
    property color color: "transparent"

    readonly property int width: Math.max(0, implicitWidth)
    readonly property int height: Math.max(0, implicitHeight)

    // mapToItem is a call, not a binding, so placement is refreshed on the events that can
    // move it rather than tracked continuously. Popups here only show on hover.
    property int surfaceX: 0
    property int surfaceY: 0

    function reposition(): void {
        const item = anchor.item;
        if (!item || !surfaceItem.parent)
            return;
        const at = item.mapToItem(surfaceItem.parent, 0, 0);
        const wanted = at.x + (item.width - width) / 2;
        const limit = Preview.screenWidth - width;
        surfaceX = Math.round(anchor.adjustment === PopupAdjustment.Slide ? Math.max(0, Math.min(wanted, limit)) : wanted);
        surfaceY = Math.round(at.y + item.height);
    }

    onVisibleChanged: reposition()
    onWidthChanged: reposition()
    onHeightChanged: reposition()

    readonly property PreviewSurface layer: PreviewSurface {
        id: surfaceItem

        win: win
    }

    Component.onCompleted: {
        Preview.addSurface(win, surfaceItem);
        reposition();
    }
    Component.onDestruction: Preview.removeSurface(win)
}
