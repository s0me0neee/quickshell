import QtQuick
import QtQuick.Effects
import Preview
import qs
import qs.services

// One ordinary window holding the whole shell: move it, resize it, minimise it, close it.
// Resizing changes the size of the virtual monitor, so the bar relayouts with it.
Window {
    id: desktop

    width: Preview.screenWidth
    height: Preview.screenHeight
    minimumWidth: 640
    minimumHeight: 360
    visible: true
    title: "quickshell preview"
    color: "#000000"

    Item {
        id: screen

        anchors.fill: parent

        // The virtual monitor is whatever size the window is
        onWidthChanged: Preview.screenWidth = width
        onHeightChanged: Preview.screenHeight = height

        Image {
            id: wallpaper

            anchors.fill: parent
            source: Preview.wallpaper
            fillMode: Image.Stretch
            smooth: true
        }

        // The wallpaper again, blurred, showing only where a surface is opaque enough.
        // That is `layerrule blur` gated by `layerrule ignorealpha` — and it is the whole
        // reason the glass in Theme.qml reads as glass.
        MultiEffect {
            anchors.fill: parent
            source: wallpaper
            visible: Preview.blur
            blurEnabled: true
            blur: Preview.blurAmount
            blurMax: Preview.blurMax
            maskEnabled: true
            maskSource: surfaceMask
            maskThresholdMin: Preview.ignoreAlpha
        }

        ShaderEffectSource {
            id: surfaceMask

            sourceItem: surfaces
            hideSource: false
            visible: false
        }

        // Every layer surface is placed in here, in creation order
        Item {
            id: surfaces

            anchors.fill: parent
        }
    }

    Component.onCompleted: {
        Preview.screenItem = surfaces;
        shell.active = true;
        if (Preview.scene("session"))
            Session.openMenu();
    }

    // Built only once the scene is ready to take surfaces
    Loader {
        id: shell

        active: false
        // shell.qml, copied under a capitalised name by mirror.py so it can be instantiated
        sourceComponent: PreviewShell {}
    }

    // A popout is a layer surface that exists from the start and only becomes visible when
    // something clicks or hovers its owner. There is no way to fake that pointer in a
    // screenshot, so they are opened by index — the run prints the list.
    function openPopout(): void {
        const popouts = Preview.surfaces.filter(s => s.open !== undefined);
        popouts.forEach((popout, i) => console.log(`[preview] popout ${i}: ${popout.implicitWidth}x${popout.implicitHeight}`));
        const wanted = parseInt(Preview.arg("--open", "-1"));
        if (wanted >= 0 && wanted < popouts.length)
            popouts[wanted].open = true;
    }

    Timer {
        running: true
        interval: 400
        onTriggered: desktop.openPopout()
    }

    // --shot: everything is one scene now, so the whole preview is a single grab
    Timer {
        running: Preview.shot !== ""
        interval: parseInt(Preview.arg("--settle", "1400"))
        onTriggered: screen.grabToImage(function (result) {
            console.log("[preview] wrote", Preview.shot, result.saveToFile(Preview.shot) ? "ok" : "FAILED");
            Qt.exit(0);
        })
    }
}
