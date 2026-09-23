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
        // Hidden popouts would otherwise follow every frame of the island's morph
        if (!bar || !target || !visible)
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

    // The surface only ever grows while the popout is open, and gives the height back
    // once it is hidden.
    //
    // This is the whole trick, and it took four goes to find. Hyprland leaves a stale
    // translucent rectangle over the area a layer surface stops covering when that
    // surface *shrinks* — growing is fine, and it is not blur, not blur caching and not
    // any single animation (all measured). Never shrinking a surface anyone can see
    // sidesteps it: the panel inside is free to be whatever height it likes, and the
    // surface catches up later, while unmapped.
    property real windowHeight: panel.targetHeight

    // The reset waits for `visible`, not for `open`: the close is a fade, and the
    // surface is still on screen for the length of it
    onVisibleChanged: {
        if (!visible)
            windowHeight = panel.targetHeight;
    }

    implicitHeight: windowHeight + Appearance.popoutGap

    // Clicks below the panel must reach whatever is under them
    mask: Region {
        item: panel
    }

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
        // Grow the surface to fit before the panel gets there, never after
        onTargetHeightChanged: root.windowHeight = Math.max(root.windowHeight, targetHeight)

        // Back now that the surface no longer resizes underneath it
        Behavior on height {
            Anim {
                easing.bezierCurve: Appearance.curveEmphasized
            }
        }
        radius: Appearance.radiusPanel
        color: Theme.panel
        border.width: 1
        border.color: Qt.alpha(Theme.outlineVariant, 0.6)
        clip: true
        opacity: root.progress
        scale: 0.94 + 0.06 * root.progress
        transformOrigin: Item.Top

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
