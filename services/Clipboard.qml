pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

Singleton {
    id: root

    property bool open: false
    property string query: ""
    property var entries: []
    property string selectedId: ""
    property string previewPath: ""
    property string previewMime: ""
    // Bumped every time the preview file is rewritten, so Image does not reuse the
    // decode it cached for the previous selection under the same path
    property int previewVersion: 0
    property string pendingId: ""
    property bool previewQueued: false

    // MIME per history id, learned once. A text entry then never spawns a process
    // again: the list's own preview line is already what the panel draws.
    property var mimeById: ({})
    // `cliphist list` only gives us a truncated preview, but that is enough to
    // recognize data:image URLs and normalize them before showing the preview.
    property var dataImageById: ({})

    // What the loader in shell.qml keys off. Asking the window for its own animation
    // progress from there is a binding loop — `active` would depend on an item that only
    // exists while `active` — so the linger is counted here instead
    readonly property bool live: open || linger.running

    onOpenChanged: {
        if (!open)
            linger.restart();
    }

    // Long enough to cover the window's close animation
    Timer {
        id: linger

        interval: 450
    }

    readonly property string previewFile: `${Quickshell.env("XDG_RUNTIME_DIR")}/quickshell-clipboard-preview`
    readonly property var filteredEntries: {
        if (query.trim() === "")
            return entries;
        const needle = query.toLowerCase();
        return entries.filter(entry => entry.preview.toLowerCase().includes(needle));
    }

    function openHistory(): void {
        open = true;
        query = "";
        refresh();
    }

    function closeHistory(): void {
        open = false;
    }

    function toggle(): void {
        if (open)
            closeHistory();
        else
            openHistory();
    }

    function refresh(): void {
        listProc.running = true;
    }

    function parseList(text: string): void {
        const next = [];
        const dataImages = {};
        for (const line of text.split("\n")) {
            const match = line.match(/^(\d+)\s+(.*)$/);
            if (!match)
                continue;
            const rawPreview = match[2] || "Clipboard item";
            const dataImage = rawPreview.match(/^data:(image\/[^;,]+);base64,/i);
            if (dataImage) {
                dataImages[match[1]] = true;
                next.push({
                    id: match[1],
                    preview: `Image address (${dataImage[1]})`
                });
                continue;
            }
            // Rich clipboard records are HTML (usually a <meta>/<img> payload)
            // with no useful plain-text preview. Keep the regular text record and
            // omit these instead of trying to render or decode them.
            if (/^\s*</.test(rawPreview))
                continue;
            next.push({
                id: match[1],
                preview: rawPreview
            });
        }
        dataImageById = dataImages;
        entries = next;
    }

    function shellQuote(value: string): string {
        return `'${value.replace(/'/g, "'\\''")}'`;
    }

    // Decodes once, straight into the preview file, and only asks `file` what it is
    // the first time that id is looked at. Keystrokes in the search box and the
    // pointer crossing a row both land here, so it is debounced rather than run.
    function inspect(entry: var): void {
        selectedId = entry.id;
        pendingId = entry.id;
        inspectTimer.restart();
    }

    function runInspect(): void {
        const id = shellQuote(pendingId);
        const known = mimeById[pendingId];
        if (known !== undefined && !known.startsWith("image/")) {
            previewMime = known;
            previewPath = "";
            return;
        }
        previewMime = known ?? "";
        previewPath = "";
        const wantMime = known === undefined;
        const isDataImage = dataImageById[pendingId] === true;
        const normalizeDataImage = `if head -c 256 "$1" | grep -q '^data:image/[^;]*;base64,'; then sed 's/^data:[^;]*;base64,//' "$1" | tr -d '\\r\\n' | base64 -d > "$1.tmp" && mv "$1.tmp" "$1"; fi`;
        previewProc.command = wantMime || isDataImage
            ? ["sh", "-c", `cliphist decode ${id} > "$1" && ${normalizeDataImage} && file --brief --mime-type "$1"`, "clipboard-preview", previewFile]
            : ["sh", "-c", `cliphist decode ${id} > "$1"`, "clipboard-preview", previewFile];
        previewProc.wantMime = wantMime;
        previewProc.forId = pendingId;
        if (previewProc.running) {
            // The previous row is still decoding; it will pick this one up when it
            // exits rather than fighting it for the same preview file
            previewQueued = true;
            return;
        }
        previewProc.running = true;
    }

    function paste(entry: var): void {
        selectedId = entry.id;
        const id = shellQuote(entry.id);
        pasteProc.command = ["sh", "-c", `cliphist decode ${id} > "$1" && mime=$(file --brief --mime-type "$1") && wl-copy --type "$mime" < "$1" && sleep 0.1 && wtype -M ctrl -k v -m ctrl`, "clipboard-paste", previewFile];
        pasteProc.running = true;
        closeHistory();
    }

    // `cliphist delete` reads the line to drop from stdin. Passing an id as an argument
    // made it read an empty stdin instead and exit 0 without touching the history.
    function deleteEntry(entry: var): void {
        deleteProc.command = ["sh", "-c", `printf '%s\\n' "$1" | cliphist delete`, "cliphist-delete", entry.id];
        deleteProc.running = true;
    }

    // Emptied here first so the panel is clean the moment the button is pressed;
    // the wipe itself only has to catch up
    function clearAll(): void {
        entries = [];
        selectedId = "";
        pendingId = "";
        previewPath = "";
        previewMime = "";
        inspectTimer.stop();
        wipeProc.running = true;
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            root.toggle();
        }
    }

    // The `bind = SUPER, V, global, qs:clipboard` line in hypr/quickshell.conf. Hyprland's
    // global dispatcher addresses a shortcut by appid:name, and Quickshell's default appid
    // is "quickshell", so both halves have to match the bind exactly.
    GlobalShortcut {
        appid: "qs"
        name: "clipboard"
        description: "Open the clipboard history"

        onPressed: root.toggle()
    }

    Process {
        id: listProc

        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parseList(text)
        }
    }

    // Rows move under the pointer while scrolling; without this every row crossed
    // would start a decode
    Timer {
        id: inspectTimer

        interval: 80
        onTriggered: root.runInspect()
    }

    Process {
        id: previewProc

        property bool wantMime: true
        // Captured at launch: the pointer may already be on another row by the time
        // this exits
        property string forId: ""

        stdout: StdioCollector {
            onStreamFinished: {
                if (previewProc.wantMime)
                    root.mimeById[previewProc.forId] = text.trim();
                const mime = root.mimeById[previewProc.forId] ?? "";
                root.previewMime = mime;
                if (mime.startsWith("image/")) {
                    root.previewPath = root.previewFile;
                    root.previewVersion += 1;
                }
            }
        }

        onExited: {
            if (!root.previewQueued)
                return;
            root.previewQueued = false;
            root.runInspect();
        }
    }

    Process {
        id: pasteProc
    }

    Process {
        id: deleteProc

        onExited: root.refresh()
    }

    Process {
        id: wipeProc

        command: ["cliphist", "wipe"]
        onExited: root.refresh()
    }
}
