pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// NOAA's hourly forecast, by way of the little Rust program in weather/.
//
// That program does the network work and prints one JSON object; everything here is
// scheduling and caching. The cache is what makes a cold start useful: the shell starts
// with whatever it knew last time and replaces it a second later, rather than showing an
// empty card while three HTTP requests happen.
Singleton {
    id: root

    readonly property string binary: `${Quickshell.env("HOME")}/.config/quickshell/weather/target/release/qs-weather`
    readonly property string cachePath: `${Quickshell.env("HOME")}/.cache/quickshell/weather.json`

    property var data: null
    property string error: ""
    property bool loading: false

    // How many weather pages are on screen. The forecast is only useful while one is,
    // so nothing fetches — and no timer ticks — when the dashboard is closed. Counting
    // readers rather than a single flag keeps two screens from turning each other off.
    property int readers: 0
    readonly property bool active: readers > 0

    readonly property bool available: data?.ok ?? false
    readonly property var now: data?.now ?? null
    readonly property var hourly: data?.hourly ?? []
    // One entry per date: { date, high, low, condition, short, precipitation }. High or
    // low is null where NOAA's week starts or ends on half a day
    readonly property var daily: data?.daily ?? []
    readonly property string city: data?.city ?? ""
    readonly property int temperature: Math.round(now?.temperature ?? 0)
    readonly property string unit: now?.unit ?? "F"
    readonly property string summary: now?.short ?? ""
    readonly property string condition: now?.condition ?? ""
    // When the reading was taken, not when the forecast was generated: the point is to
    // know whether what is on screen is stale
    readonly property date updated: data?.updated ? new Date(data.updated) : new Date(0)

    // NOAA regenerates hourly, so anything tighter is asking to be throttled
    readonly property int refreshInterval: 20 * 60 * 1000

    function watch(): void {
        readers += 1;
        if (readers === 1)
            refresh();
    }

    function unwatch(): void {
        readers = Math.max(0, readers - 1);
    }

    function refresh(): void {
        if (!proc.running)
            proc.running = true;
    }

    function apply(text: string): void {
        const parsed = JSON.parse(text);
        if (!parsed.ok)
            throw new Error(parsed.error ?? "the forecast failed for an unstated reason");
        root.data = parsed;
        root.error = "";
    }

    Timer {
        interval: root.refreshInterval
        running: root.active
        repeat: true
        onTriggered: root.refresh()
    }

    // Last good answer, so the card has something to show before the first fetch returns
    FileView {
        id: cache

        path: root.cachePath
        onLoaded: {
            // A fresh fetch may already have landed; it wins
            if (root.data === null) {
                try {
                    root.apply(text());
                } catch (e) {
                    // A stale or half-written cache is not worth reporting: the fetch
                    // already under way is about to replace it either way
                }
            }
        }
    }

    Process {
        id: proc

        command: [root.binary]
        onRunningChanged: root.loading = running
        onExited: (code, status) => {
            if (code !== 0 && root.data === null)
                root.error = `weather: ${root.binary} exited ${code}. Has it been built? cargo build --release`;
        }

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.apply(text);
                    cache.setText(text);
                } catch (e) {
                    root.error = `${e}`;
                }
            }
        }
    }
}
