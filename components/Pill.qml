import QtQuick
import QtQuick.Layouts
import qs.common

// A floating glass capsule that groups bar items. Scroll is reported for every group;
// clicks only when `interactive`.
Rectangle {
    id: root

    default property alias content: row.data
    property real padding: Appearance.groupPadding
    property alias spacing: row.spacing
    property bool interactive: false
    property bool active: false
    readonly property bool hovered: hover.hovered

    signal clicked(var mouse)
    signal scrolled(int delta)

    implicitWidth: row.implicitWidth + padding * 2
    implicitHeight: Appearance.groupHeight
    radius: height / 2
    color: Theme.glass
    border.width: 1
    border.color: Theme.glassEdge
    scale: interactive && mouse.pressed ? 0.96 : 1

    // Still wanted: the glass colour itself changes when the wallpaper palette does
    Behavior on color {
        CAnim {
            duration: Appearance.animFast
        }
    }

    Behavior on scale {
        Anim {
            duration: Appearance.animFast
        }
    }

    Behavior on implicitWidth {
        Anim {
            duration: Appearance.animNormal
        }
    }

    HoverHandler {
        id: hover
    }

    // Declared before the content so buttons inside the group get their clicks first
    MouseArea {
        id: mouse

        anchors.fill: parent
        acceptedButtons: root.interactive ? (Qt.LeftButton | Qt.RightButton | Qt.MiddleButton) : Qt.NoButton
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: event => root.clicked(event)
        onWheel: event => root.scrolled(event.angleDelta.y)
    }

    // Before the content, so the tint sits under the icons rather than over them
    StateLayer {
        radius: root.radius
        tone: Theme.surfaceText
        hovered: root.interactive && root.hovered
        pressed: root.interactive && mouse.pressed
        active: root.interactive && root.active
    }

    RowLayout {
        id: row

        anchors.centerIn: parent
        spacing: Appearance.spacingSmall
    }
}
