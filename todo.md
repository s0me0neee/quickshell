# Todo

## Done

1. Refine workspace animation — the capsule draws over the dots, and a dot only hides
   once the capsule has swallowed it
2. Taskbar icons looked blurred — we asked the icon theme for 18px, a size no theme
   ships, so Qt rendered the nearest and rescaled. Now 22, the freedesktop panel size
3. Control center — brightness and the power profile folded into one button, plus the
   Wi-Fi / Bluetooth / microphone / do-not-disturb tiles and the paired-device list

## Now

### 9. Settings page — **next, and needs the page list agreed first**

Only the settings that get changed often, and the ones that are a pain to change by
hand. Not a second copy of every dotfile. Clavis's shape: a navigation rail down the
left, one page at a time on the right, cards inside a page — drawn in our own glass.

- [ ] Agree the page list before building any of it
- [ ] A window, not a popout: it is too big to hang off the bar
- [ ] Settings persist to JSON outside git, next to `colors.json`

## Done in this round

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
- [x] 28 bars at 30fps, config in `assets/cava.conf`
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

## Later

- Make it look really nice
- Right-click a control-center tile to open its detail panel (Clavis does this)
- VPN tile — there is a ProtonVPN profile in NetworkManager already
