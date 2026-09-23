# Todo

## Done

1. Refine workspace animation — the capsule draws over the dots, and a dot only hides
   once the capsule has swallowed it
2. Taskbar icons looked blurred — we asked the icon theme for 18px, a size no theme
   ships, so Qt rendered the nearest and rescaled. Now 22, the freedesktop panel size
3. Control center — brightness and the power profile folded into one button, plus the
   Wi-Fi / Bluetooth / microphone / do-not-disturb tiles and the paired-device list

## Done in this round

### 9. Settings page

Only the settings that get changed often, and the ones that are a pain to change by
hand. Not a second copy of every dotfile. Clavis's shape: a navigation rail down the
left, one page at a time on the right, cards inside a page — drawn in our own glass.

**Decided:** four pages, opened from a `⚙ Settings ›` row at the bottom of the control
center. No new bar button, no keybind for now.

- [x] `services/Settings.qml` — one JSON file in `~/.local/state/quickshell/`, next to
      `colors.json`, so it is generated state and never shows as a repo change
- [x] The window itself, opened from the control center's `⚙ Settings ›` row
- [x] **Appearance** — glass opacity, corner radius, base font size
- [x] **Bar** — which status buttons show, 12/24h clock, which dashboard tab opens first
- [x] **Media** — visualiser on/off, bar count, frame rate. Changing either number
      rewrites the generated cava config and restarts cava
- [x] **Units** — °F/°C, mph/km-h, GiB/GB, applied on the way to the screen so changing
      one never re-fetches anything
- [x] Every control reaches the thing it names; checked one at a time
- **No light/dark switch.** matugen writes one palette for the whole desktop, so the
  button would recolour Hyprland too. The page says so rather than pretending

### 4. Keep awake toggle

A fifth tile in the control center. `IdleInhibitor` is in `Quickshell.Wayland` in 0.3.1,
so this needs no external process and no new dependency. Worth having: hypridle locks the
session at 10 min and suspends at 30, which fights anything watched fullscreen.

- [x] `services/Idle.qml` — the Wayland inhibitor, plus the time it was switched on
- [x] Tile in the control center, spanning the row, subtitle "Normal sleep" / "Since 21:40"
- [x] Survives a shell reload (`PersistentProperties`)

### 5. Dashboard, under the clock

**Decided:** the island's date popout grows into a dashboard, switchable between a few
pages the way Clavis switches its info tools — a small tab strip with an underline that
stretches toward the tab you picked and then contracts behind it. One page at a time.

**Clean and simple is the brief.** Enough to understand at a glance, not a wall of
figures. If a page needs a scrollbar it is doing too much.

- [x] `components/TabStrip.qml` — the underline stretches toward the tab you picked and
      contracts behind it, from two numbers chasing the same index at different speeds
- [x] Calendar page — what the popout already drew, lifted out of the Popout
- [x] Weather page
- [x] System page
- Gotcha worth remembering: a `ColumnLayout` nested straight inside a `RowLayout`
  sizes itself from its contents and ignores `Layout.fillWidth`. Both the dials and the
  hourly columns huddled at the left until each was wrapped in a plain `Item`

### 6. Audio visualiser, in the media card

**Decided:** bars in the hover card the island already opens, not in the bar itself.

Caelestia links libcava in C++, which this config does not do. `cava` is installed and can
write raw values to stdout, so a `Process` plus a parser gets the same data with no build
step.

**Watch the cost.** This is the one thing here that redraws continuously, and PLAN.md's
performance rules say nothing may loop while idle. So:

- [x] cava starts only when the card is open *and* something is actually playing, and is
      killed the moment either stops. `pgrep cava` returns nothing with the card shut
- [x] 28 bars at 30fps by default, both settable; the config is generated into
      `~/.local/state/quickshell/cava.conf` rather than shipped in the repo
- [x] Measured, and written into PLAN.md: about 7% of one core while on screen, nothing
      when closed. Left in on that basis — say the word if it is not worth it

### 7. Weather

**Decided:** a standalone crate in this repo, so the config stays self-contained.

`~/code/rust/deskdock/desktop/deskdock-weather` already does the work: IP geolocation, then
NOAA's hourly forecast. It is a library inside the deskdock workspace and speaks protobuf
to the firmware, so the shell cannot use it as-is.

- [x] `weather/` crate here: three GETs and serde_json, no `deskdock-proto` and no
      generated NOAA client. Two tests. `QS_WEATHER_LATLON` overrides the IP lookup,
      which matters with the VPN on
- [x] `services/Weather.qml` — refreshes every 20 minutes, caches the last good reading
      to `~/.cache/quickshell/weather.json` so a cold start is not blank
- [x] NOAA is US-only; the crate says so rather than failing silently
- [x] README: dependencies, the one-off `cargo build --release`, and the VPN caveat

### 8. CPU and memory

`/proc/stat` and `/proc/meminfo`, read on a timer while the page showing them is open, and
not otherwise. No dependency, no daemon.

- [x] `services/SysStats.qml` — CPU from /proc/stat deltas, memory from MemAvailable,
      plus uptime and load. Reader-counted: the timer only runs while the page is open
- [x] Ring per figure, in the same dial language as the volume and battery

### 10. Popout height: four attempts, and what it actually was

The clock panel dragged a ghost of itself when a tab made it shorter. Every wrong guess
is worth keeping, because each one looked like the fix for the last:

| | surface resizes | band inside the surface | result |
| --- | --- | --- | --- |
| Original | per frame, on shrink | on grow | "laggy and not smooth" |
| Ease the panel inside a held window | 2, one of them a shrink | for the animation | "drag trails" |
| Glue the window to the panel | per frame | never | "still jitters" |
| Snap the height | 1, a shrink | never | still trails, on decrease only |

**It is the surface shrinking. Nothing else.** Hyprland leaves a stale translucent
rectangle over the area a layer surface stops covering when that surface gets smaller.
Growing is fine. Measured and ruled out: blur (`blur off` on the layer — still trails),
blur caching (`new_optimizations false` — still trails), the layers animation, the fade
tree, the windows tree. Only `animations:enabled 0` hid it, which is not a fix anyone
would accept.

- [x] The surface now only ever *grows* while the popout is open, and gives the height
      back in `onVisibleChanged`, once it is unmapped and nobody can see it shrink
- [x] `mask: Region { item: panel }` so the taller-than-it-looks surface doesn't eat
      clicks meant for whatever is underneath
- [x] The eased height is back, since the surface no longer resizes during it
- [x] Verified through the real click path, single clean instance, no ghost band

**How to test this class of bug**, because it cost several rounds to work out:

- `grim` is useless here. It asks the compositor to re-render, which erases the
  artifact. Screenshots came back clean while the trail was plainly visible
- `wf-recorder -r 60` *does* capture it, and so does `ffmpeg -f kmsgrab` (the latter
  needs `hwmap=derive_device=vaapi` on Intel — the framebuffer is tiled and cannot be
  copied to the CPU)
- The harness is in the scratchpad: `shrink.sh` records one shrink, `analyse.py` diffs
  the vacated band against the settled frame and prints how far off each frame is.
  A three-line `IpcHandler` in Dashboard.qml made runs repeatable; removed again

### 11. The island hub

**Decided:** tabs, one page at a time (Clavis's hub, not its all-at-once dashboard); the
whole island is one target; the weather page gets NOAA's 7-day forecast.

- [x] Hover anywhere on the island opens the media card; right-click anywhere opens the hub
- [x] Hub is 720 wide under the island: Media, Weather, Calendar, System
- [x] Media: the media card, taller, with the album
- [x] Weather: now + 12 hours, then 7 days with low-high bars on one shared scale.
      `weather/` fetches NOAA's daily forecast too; a failure there only empties the week
- [x] Calendar: big clock and date beside the month; System: three dials beside the details
- [x] `hubTab` setting by name ("calendar" by default, which is what the old index 0 meant)

## Later

- Make it look really nice — now itemised as PLAN.md's **Visual gaps** table, in the
  order worth doing. Ripple/state layer is first and cheapest
- Phases 6–9 (lyrics, desktop layer, sidebar drawer, lock screen) are in PLAN.md as of
  2026-09-22, each with a budget it has to meet or be reverted
- Right-click a control-center tile to open its detail panel (Clavis does this)
- VPN tile — there is a ProtonVPN profile in NetworkManager already
