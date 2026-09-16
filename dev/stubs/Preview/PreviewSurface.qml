import QtQuick

// The Item a layer surface actually draws into. It lives in the one shared scene rather
// than in a window of its own, which is what lets the whole shell be moved, resized and
// screenshotted as a single ordinary window.
Item {
    id: surface

    required property var win

    x: win.surfaceX
    y: win.surfaceY
    width: win.width
    height: win.height
    visible: win.visible

    Rectangle {
        anchors.fill: parent
        color: surface.win.color
    }
}
