pragma Singleton

import QtQuick

// Preview-only settings, read off the command line so preview.sh stays a one-liner:
//   qml preview.qml -- --shot bar.png --scenario media,notifs
QtObject {
    id: root

    function arg(name: string, fallback: string): string {
        const args = Qt.application.arguments;
        const i = args.indexOf(name);
        return i >= 0 && i + 1 < args.length ? args[i + 1] : fallback;
    }

    function flag(name: string): bool {
        return Qt.application.arguments.indexOf(name) >= 0;
    }

    // Comma-separated, so several can be combined
    function scene(name: string): bool {
        return scenario.split(",").indexOf(name) >= 0;
    }

    readonly property string scenario: arg("--scenario", "media,tray")

    // The virtual monitor every layer surface is laid out against. preview.qml keeps these
    // tied to the window's content area, so resizing the window relayouts the bar.
    property int screenWidth: parseInt(arg("--width", "1280"))
    property int screenHeight: parseInt(arg("--height", "800"))

    readonly property url wallpaper: arg("--wallpaper", "")
    readonly property url artwork: arg("--artwork", "")
    // Directory the generated tray/notification icons live in
    readonly property string icons: arg("--icons", "")
    // Theme.qml builds its colors path out of $HOME, so pointing HOME at the mock tree is
    // enough to feed it a palette without touching the shell's code
    readonly property string home: arg("--home", "")
    readonly property string shot: arg("--shot", "")

    // Hyprland blurs a layer surface only where it is opaque enough:
    //   layerrule = blur, qs-bar   +   layerrule = ignorealpha 0.1, qs-bar
    // preview.qml reproduces that with a blurred wallpaper masked by the surfaces' alpha.
    readonly property bool blur: !flag("--no-blur")
    readonly property real blurAmount: parseFloat(arg("--blur", "1.0"))
    readonly property int blurMax: parseInt(arg("--blur-max", "40"))
    readonly property real ignoreAlpha: 0.1

    // The Item every surface is placed in, set by preview.qml before the shell loads
    property Item screenItem: null

    // Layer surfaces are stacked in creation order, which puts popouts over the bar and
    // the session menu over everything, the way the wlr layers would
    property var surfaces: []

    function addSurface(win: var, item: Item): void {
        surfaces = surfaces.concat([win]);
        item.parent = screenItem;
    }

    function removeSurface(win: var): void {
        surfaces = surfaces.filter(s => s !== win);
    }
}
