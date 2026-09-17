import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.common

// A panel that drops out of the bar, centered under the item it belongs to.
// It is a layer surface rather than an xdg popup, so clicks inside keep it open
// and it can take keyboard input (e.g. a wifi password).
PanelWindow {
    id: root

    required property Item target
    required property var bar
    property bool open: false
    property bool wantsKeyboard: false
    // Off for panels that open on hover: a grab would eat the next click anywhere
    // on screen, and the thing that opened it also closes it
    property bool grabsFocus: true
    readonly property bool hovered: panelHover.hovered
    property real contentWidth: -1
    default property alias content: column.data

    // Horizontal center of the target in screen coordinates. Reading x/width of the target
    // and its parents makes this re-evaluate whenever the bar layout moves them.
    readonly property real anchorX: {
        if (!bar || !target)
            return 0;
        target.x + target.width + (target.parent?.x ?? 0) + (target.parent?.parent?.x ?? 0) + bar.width;
        return bar.margins.left + target.mapToItem(bar.contentItem, target.width / 2, 0).x;
    }
    property real progress: open ? 1 : 0

    function toggle(): void {
        open = !open;
    }

    onOpenChanged: {
        if (open) {
            PopoutState.current = root;
        } else if (PopoutState.current === root) {
            PopoutState.current = null;
        }
    }

    Connections {
        target: PopoutState

        function onCurrentChanged(): void {
            if (PopoutState.current !== root)
                root.open = false;
        }
    }

    screen: bar.screen
    visible: open || progress > 0
    color: "transparent"
    anchors.top: true
    anchors.left: true
    margins.top: Appearance.barMarginTop + Appearance.barHeight
    margins.left: {
        const screenWidth = bar.screen?.width ?? 1920;
        const wanted = anchorX - implicitWidth / 2;
        return Math.round(Math.max(Appearance.barMarginSide, Math.min(wanted, screenWidth - implicitWidth - Appearance.barMarginSide)));
    }
    exclusionMode: ExclusionMode.Ignore
    implicitWidth: panel.width
    // The window steps, the panel inside it eases.
    //
    // Following `panel.height` here instead resized the layer surface on every frame of
    // the animation — sixty reconfigures a second, which is what made a tall panel feel
    // like it was dragging. Now the window jumps straight to whichever is taller, the
    // height it is leaving or the one it is heading for, and only comes back down once
    // the panel has finished moving. The surface changes size twice per animation, and
    // the easing everyone actually sees happens inside it.
    property real windowHeight: panel.targetHeight
    implicitHeight: windowHeight + Appearance.popoutGap

    WlrLayershell.namespace: "qs-popout"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: open && wantsKeyboard ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Behavior on progress {
        Anim {
            duration: root.open ? Appearance.animSlow : Appearance.animNormal
            easing.bezierCurve: root.open ? Appearance.curveEmphasized : Appearance.curveStandard
        }
    }

    // Clicking anywhere outside the popout and the bar closes it
    HyprlandFocusGrab {
        active: root.open && root.visible && root.grabsFocus
        windows: [root, root.bar]
        onCleared: root.open = false
    }

    Rectangle {
        id: panel

        readonly property real targetHeight: column.implicitHeight + Appearance.spacingLarge * 2

        y: Appearance.popoutGap - 10 * (1 - root.progress)
        width: (root.contentWidth > 0 ? root.contentWidth : column.implicitWidth) + Appearance.spacingLarge * 2
        height: targetHeight
        radius: Appearance.radiusPanel
        color: Theme.panel
        border.width: 1
        border.color: Qt.alpha(Theme.outlineVariant, 0.6)
        clip: true
        opacity: root.progress
        scale: 0.94 + 0.06 * root.progress
        transformOrigin: Item.Top

        // Room for both ends of the move before it starts, so a growing panel is never
        // clipped and a shrinking one doesn't drag the surface down with it
        onTargetHeightChanged: root.windowHeight = Math.max(root.windowHeight, targetHeight)

        Behavior on height {
            Anim {
                easing.bezierCurve: Appearance.curveEmphasized
                // Only now is it safe to give the extra height back
                onRunningChanged: {
                    if (!running)
                        root.windowHeight = panel.targetHeight;
                }
            }
        }

        Keys.onEscapePressed: root.open = false

        HoverHandler {
            id: panelHover
        }

        ColumnLayout {
            id: column

            x: Appearance.spacingLarge
            y: Appearance.spacingLarge
            width: panel.width - Appearance.spacingLarge * 2
            spacing: Appearance.spacing
        }
    }
}
