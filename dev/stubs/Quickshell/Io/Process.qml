import QtQuick
import Preview

// Nothing is spawned. Most services that use this are mocked further up, but the ones
// that only exist as a command — brightnessctl — get a canned answer here instead.
QtObject {
    id: root

    property var command: []
    property bool running: false
    property QtObject stdout: null
    property QtObject stderr: null

    signal exited(int exitCode, int exitStatus)

    function startDetached(): void {}

    // Returns what the command would have printed, or null for one nothing fakes
    function answer(argv: var): var {
        if (argv[0] !== "brightnessctl")
            return null;
        const i = argv.indexOf("set");
        if (i < 0)
            return Backlight.list();
        const d = argv.indexOf("-d");
        return Backlight.set(d >= 0 ? argv[d + 1] : "", parseInt(argv[i + 1]));
    }

    onRunningChanged: {
        if (!running)
            return;
        console.log("[preview] Process:", JSON.stringify(command));
        const out = answer(command);
        running = false;
        // Left silent when nothing is faked, so a service waiting on output keeps waiting
        // rather than parsing an empty string it would never see on a real system
        if (out !== null && stdout) {
            stdout.text = out;
            stdout.streamFinished();
        }
        exited(0, 0);
    }
}
