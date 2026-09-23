pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// The launcher, replacing `rofi -show drun` and `rofi -show calc`.
//
// Two modes in one window. Apps rank through the `qs-search` worker: the shell owns the
// data (Quickshell parses desktop entries properly — icons, actions, execute()) and the
// worker only scores, so one process lives for the life of the window rather than one
// per keystroke. Calc shells out to `qalc`, which is a real process each time and so is
// debounced.
Singleton {
    id: root

    // "apps" or "calc"
    property string mode: "apps"
    property bool open: false
    property string query: ""

    // Ids from the worker, best first. Empty query means "no opinion" and the worker
    // hands the corpus back in the order we sent it.
    property var rankedIds: []
    property string calcResult: ""
    property string calcError: ""

    readonly property string binary: `${Quickshell.env("HOME")}/.config/quickshell/tools/qs-search/target/release/qs-search`

    // What the loader in shell.qml keys off. Counted here, not from the window's own
    // animation: `active` must not depend on an item that only exists while active.
    readonly property bool live: open || linger.running

    // Every app worth showing, most recently launched first and the rest alphabetical —
    // the ordering rofi's drun had. This is also what the worker falls back to on an
    // empty query, and its tiebreak when two entries score equally, so recency carries
    // into search results without the matcher knowing anything about it.
    readonly property var apps: {
        const all = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        const byName = all.slice().sort((a, b) => a.name.localeCompare(b.name));

        const rank = {};
        const recent = usageAdapter.recent ?? [];
        for (let i = 0; i < recent.length; i++)
            rank[recent[i]] = i;

        // Two buckets rather than one comparator: an id that has dropped off the recent
        // list must not sort against one that is still on it
        const used = byName.filter(e => rank[e.id] !== undefined).sort((a, b) => rank[a.id] - rank[b.id]);
        const rest = byName.filter(e => rank[e.id] === undefined);
        return [...used, ...rest];
    }

    // Rebuilt from the ids the worker returned. Ids that no longer resolve are dropped
    // rather than left as holes in the list.
    readonly property var results: {
        if (mode !== "apps")
            return [];
        return rankedIds.map(id => DesktopEntries.byId(id)).filter(e => e);
    }

    function openMode(which: string): void {
        mode = which;
        query = "";
        rankedIds = [];
        calcResult = "";
        calcError = "";
        open = true;
        // The corpus goes over once the worker is up; see onRunningChanged below
        if (which === "apps")
            search.running = true;
    }

    function close(): void {
        open = false;
        query = "";
        // Killed on close, so nothing of ours is running while the launcher isn't shown
        search.running = false;
        calcProc.running = false;
        calcDebounce.stop();
    }

    function toggle(which: string): void {
        if (open && mode === which)
            close();
        else
            openMode(which);
    }

    function launch(entry: DesktopEntry): void {
        if (!entry)
            return;
        remember(entry.id);
        close();
        entry.execute();
    }

    // Most recent first. An id already in the list moves to the front rather than being
    // added twice, and the tail is dropped so this can't grow without limit.
    function remember(id: string): void {
        if (!id)
            return;
        const next = [id, ...(usageAdapter.recent ?? []).filter(other => other !== id)];
        usageAdapter.recent = next.slice(0, 50);
        usageFile.writeAdapter();
    }

    // What the rofi calc modi did on Return. wl-copy is already how the clipboard
    // service puts things on the board, so this adds no new dependency.
    function copyResult(): void {
        if (calcResult === "")
            return;
        copyProc.command = ["wl-copy", "--", calcResult];
        copyProc.running = true;
        close();
    }

    Process {
        id: copyProc
    }

    onQueryChanged: {
        if (mode === "apps")
            sendQuery();
        else
            calcDebounce.restart();
    }

    function sendQuery(): void {
        if (!search.running)
            return;
        search.write(`${JSON.stringify({
            q: root.query,
            limit: 40
        })}\n`);
    }

    function sendCorpus(): void {
        // `text` is what gets matched: the name, plus the subtitle and keywords, so
        // "browser" finds Firefox and "img" finds GIMP
        const set = root.apps.map(e => ({
            id: e.id,
            text: [e.name, e.genericName, e.comment, (e.keywords ?? []).join(" ")].filter(s => s).join("  ")
        }));
        search.write(`${JSON.stringify({
            set
        })}\n`);
        sendQuery();
    }

    // Generated state, next to settings.json — not config, so it never shows as a repo
    // change
    readonly property string usagePath: `${Quickshell.env("HOME")}/.local/state/quickshell/launcher.json`
    readonly property alias usage: usageAdapter

    FileView {
        id: usageFile

        path: root.usagePath
        watchChanges: true
        // First run has no file; writing one is how it gets created
        onLoadFailed: error => writeAdapter()
        onFileChanged: reload()

        JsonAdapter {
            id: usageAdapter

            // Ids of recently launched apps, most recent first
            property list<string> recent: []
        }
    }

    Timer {
        id: linger

        interval: 450
    }

    onOpenChanged: {
        if (!open)
            linger.restart();
    }

    Process {
        id: search

        command: [root.binary]
        stdout: SplitParser {
            onRead: line => {
                const msg = JSON.parse(line);
                if (msg.ids)
                    root.rankedIds = msg.ids;
            }
        }

        onRunningChanged: {
            if (running)
                root.sendCorpus();
        }

        onExited: (code, status) => {
            if (root.open && code !== 0)
                root.calcError = `qs-search exited ${code}. Has it been built? cargo build --release in tools/qs-search`;
        }
    }

    // A process per keystroke is exactly what the worker exists to avoid, but qalc has
    // no streaming mode, so this pays for itself with a debounce instead.
    Timer {
        id: calcDebounce

        interval: 120
        onTriggered: {
            if (root.query.trim() === "") {
                root.calcResult = "";
                root.calcError = "";
                return;
            }
            calcProc.running = false;
            calcProc.running = true;
        }
    }

    Process {
        id: calcProc

        // -t is terse: the result on its own, with no echo of the expression
        command: ["qalc", "-t", root.query]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = text.trim();
                // qalc answers in prose when it can't evaluate, and still exits 0
                if (out === "" || /^error/i.test(out)) {
                    root.calcResult = "";
                    root.calcError = out;
                } else {
                    root.calcResult = out;
                    root.calcError = "";
                }
            }
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggle("apps");
        }

        function calc(): void {
            root.toggle("calc");
        }
    }

    // `bind = CTRL, space, global, qs:launcher` in hypr/quickshell.conf. Hyprland
    // addresses a shortcut by appid:name, and Quickshell's default appid is
    // "quickshell", so both halves have to match the bind exactly.
    GlobalShortcut {
        appid: "qs"
        name: "launcher"
        description: "Open the app launcher"

        onPressed: root.toggle("apps")
    }

    GlobalShortcut {
        appid: "qs"
        name: "calc"
        description: "Open the calculator"

        onPressed: root.toggle("calc")
    }
}
