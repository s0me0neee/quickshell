import QtQuick

// Quickshell clips children to the rounded shape with a custom scene graph node. There
// is no pure-QML equivalent — a MultiEffect/OpacityMask mask needs its mask item to be
// rendering on screen, which defeats the point — so this clips to the bounding box
// instead. The one place it shows is the album art in MediaCard: square corners here,
// rounded on Hyprland. Everything else puts its content well inside the corners.
Rectangle {
    id: root

    property bool contentInsideBorder: false
    default property alias contentData: content.data

    clip: true

    Item {
        id: content

        anchors.fill: parent
        anchors.margins: root.contentInsideBorder ? root.border.width : 0
    }
}
