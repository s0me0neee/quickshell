pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// The handful of things worth changing without opening an editor.
//
// Deliberately not a copy of every token in Appearance.qml: what lives here is what
// gets changed often, or what is a nuisance to change by hand. Everything else stays a
// constant in the source where it belongs.
//
// Stored next to colors.json, in ~/.local/state — generated state, not config, so it
// never shows up as a change in this repo.
Singleton {
    id: root

    property bool menuOpen: false

    // What the loader in shell.qml keys off. Asking the window for its own animation
    // progress from there is a binding loop — `active` would depend on an item that only
    // exists while `active` — so the linger is counted here instead
    readonly property bool menuLive: menuOpen || linger.running

    readonly property string path: `${Quickshell.env("HOME")}/.local/state/quickshell/settings.json`
    readonly property alias data: adapter

    function open(): void {
        menuOpen = true;
    }

    function close(): void {
        menuOpen = false;
    }

    onMenuOpenChanged: {
        if (!menuOpen)
            linger.restart();
    }

    // Long enough to cover the window's close animation. A literal rather than
    // Appearance.animNormal: common/Appearance.qml reads this singleton, and importing
    // it back would make the two depend on each other
    Timer {
        id: linger

        interval: 450
    }

    // Every page writes through this, so one place decides when the file is written
    function save(): void {
        file.writeAdapter();
    }

    // --- unit conversion -------------------------------------------------------
    //
    // The weather program reports NOAA's own units, °F and mph, and /proc counts in
    // kibibytes. Nothing is converted on the way in; it happens here, on the way to
    // the screen, so the cached reading stays the reading NOAA actually gave.

    // One place decides 12- or 24-hour, so the bar clock, the weather columns and the
    // keep-awake tile can't drift apart
    function time(value: var): string {
        return Qt.formatTime(value, adapter.twelveHour ? "h:mm AP" : "HH:mm");
    }

    function hour(value: var): string {
        return Qt.formatTime(value, adapter.twelveHour ? "hAP" : "HH");
    }

    readonly property string temperatureUnit: adapter.celsius ? "C" : "F"

    function temperature(fahrenheit: real): real {
        return adapter.celsius ? (fahrenheit - 32) * 5 / 9 : fahrenheit;
    }

    readonly property string windUnit: adapter.metricWind ? "km/h" : "mph"

    function wind(mph: real): real {
        return adapter.metricWind ? mph * 1.609344 : mph;
    }

    // GiB is what /proc means; GB is what the sticker on the machine said
    readonly property string memoryUnit: adapter.decimalBytes ? "GB" : "GiB"

    function memory(kib: real): real {
        return kib * 1024 / (adapter.decimalBytes ? 1e9 : 1073741824);
    }

    FileView {
        id: file

        path: root.path
        watchChanges: true
        // First run has no file; writing one is how it gets created
        onLoadFailed: error => writeAdapter()
        onFileChanged: reload()

        JsonAdapter {
            id: adapter

            // --- appearance ---
            // How see-through every surface is. 0.4 is what the old waybar used
            property real glassOpacity: 0.4
            property int radiusPanel: 24
            property int fontSize: 14

            // --- bar ---
            property bool showNetwork: true
            property bool showVolume: true
            property bool showBattery: true
            property bool showControlCenter: true
            property bool showTray: true
            property bool twelveHour: false
            // Which hub tab a right-click on the island opens: media, weather, calendar
            // or system. A name, not an index, so adding a tab never re-points it
            property string hubTab: "calendar"

            // --- media and sound ---
            property bool visualiser: true
            // Changing either of these rewrites assets/cava.conf and restarts cava
            property int visualiserBars: 28
            property int visualiserFramerate: 30

            // --- units ---
            property bool celsius: false
            property bool metricWind: false
            property bool decimalBytes: false
        }
    }
}
