pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// CPU and memory load, straight out of /proc.
//
// Polled, which the rest of the shell avoids — but there is no kernel event for "the CPU
// got busier", so a timer is the only way. It only runs while something is watching:
// take a reader while your page is open, drop it when it closes, and nothing ticks in
// between. See `sample()`.
Singleton {
    id: root

    // 0-1, like every other level in the shell
    property real cpu: 0
    property real memory: 0

    property real memoryUsedKb: 0
    property real memoryTotalKb: 0

    readonly property string memoryText: `${scaled(memoryUsedKb)} / ${scaled(memoryTotalKb)} ${Settings.memoryUnit}`

    // Runnable processes averaged over the last minute, not a percentage
    property real loadAverage: 0

    property real uptimeSeconds: 0
    readonly property string uptimeText: {
        const days = Math.floor(uptimeSeconds / 86400);
        const hours = Math.floor(uptimeSeconds % 86400 / 3600);
        const minutes = Math.floor(uptimeSeconds % 3600 / 60);
        if (days > 0)
            return `${days}d ${hours}h`;
        return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
    }

    // How many pages are open that show these figures. The timer follows it
    property int readers: 0

    // Previous /proc/stat totals, to turn two counters into a rate
    property real lastBusy: 0
    property real lastTotal: 0

    function watch(): void {
        readers += 1;
    }

    function unwatch(): void {
        readers = Math.max(0, readers - 1);
    }

    // GiB or GB, whichever the settings ask for
    function scaled(kb: real): string {
        return Settings.memory(kb).toFixed(1);
    }

    // /proc/stat's first line counts jiffies since boot per state. The load over the last
    // interval is the change in busy jiffies over the change in all of them
    function readCpu(text: string): void {
        const fields = text.split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        if (fields.length < 4)
            return;
        const total = fields.reduce((sum, n) => sum + n, 0);
        const idle = fields[3] + (fields[4] ?? 0);
        const busy = total - idle;

        if (lastTotal > 0 && total > lastTotal)
            cpu = Math.max(0, Math.min(1, (busy - lastBusy) / (total - lastTotal)));
        lastBusy = busy;
        lastTotal = total;
    }

    // MemAvailable, not MemFree: free counts the page cache as used, which on a machine
    // that has been up a while reads as permanently full
    function readMemory(text: string): void {
        const find = key => {
            const match = text.match(new RegExp(`^${key}:\\s+(\\d+)`, "m"));
            return match ? Number(match[1]) : 0;
        };
        const total = find("MemTotal");
        const available = find("MemAvailable");
        if (total <= 0)
            return;
        memoryTotalKb = total;
        memoryUsedKb = total - available;
        memory = memoryUsedKb / total;
    }

    function sample(): void {
        stat.reload();
        meminfo.reload();
        uptime.reload();
        loadavg.reload();
    }

    Timer {
        // Slow enough to be honest about an average, quick enough to feel live
        interval: 2000
        running: root.readers > 0
        repeat: true
        // The first tick only establishes the baseline, so take one straight away
        triggeredOnStart: true
        onTriggered: root.sample()
    }

    FileView {
        id: stat

        path: "/proc/stat"
        onLoaded: root.readCpu(text())
    }

    FileView {
        id: meminfo

        path: "/proc/meminfo"
        onLoaded: root.readMemory(text())
    }

    // "<up> <idle>", both in seconds
    FileView {
        id: uptime

        path: "/proc/uptime"
        onLoaded: root.uptimeSeconds = parseFloat(text().split(" ")[0]) || 0
    }

    // "<1min> <5min> <15min> <running/total> <lastpid>"
    FileView {
        id: loadavg

        path: "/proc/loadavg"
        onLoaded: root.loadAverage = parseFloat(text().split(" ")[0]) || 0
    }
}
