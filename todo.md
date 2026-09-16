# Todo

## Done

1. Refine workspace animation — the capsule draws over the dots, and a dot only hides
   once the capsule has swallowed it
2. Taskbar icons looked blurred — we asked the icon theme for 18px, a size no theme
   ships, so Qt rendered the nearest and rescaled. Now 22, the freedesktop panel size
3. Control center — brightness and the power profile folded into one button, plus the
   Wi-Fi / Bluetooth / microphone / do-not-disturb tiles and the paired-device list

## Now

### 4. Keep awake toggle

A fifth tile in the control center. `IdleInhibitor` is in `Quickshell.Wayland` in 0.3.1,
so this needs no external process and no new dependency. Worth having: hypridle locks the
session at 10 min and suspends at 30, which fights anything watched fullscreen.

- [ ] `services/Idle.qml` — the inhibitor, plus the time it was switched on
- [ ] Tile in the control center, subtitle "Normal sleep" / "Awake since 21:40"
- [ ] Survives a shell reload (`PersistentProperties`)

### 5. Dashboard, under the clock

**Decided:** the island's date popout grows into a dashboard, switchable between a few
pages the way Clavis switches its info tools — a small tab strip with an underline that
stretches toward the tab you picked and then contracts behind it. One page at a time.

**Clean and simple is the brief.** Enough to understand at a glance, not a wall of
figures. If a page needs a scrollbar it is doing too much.

- [ ] Tab strip component, in our own motion language rather than a copied TabBar
- [ ] Calendar page — what the popout already draws
- [ ] Weather page (see 7)
- [ ] System page (see 8)

### 6. Audio visualiser, in the media card

**Decided:** bars in the hover card the island already opens, not in the bar itself.

Caelestia links libcava in C++, which this config does not do. `cava` is installed and can
write raw values to stdout, so a `Process` plus a parser gets the same data with no build
step.

**Watch the cost.** This is the one thing here that redraws continuously, and PLAN.md's
performance rules say nothing may loop while idle. So:

- [ ] cava starts only when the card is open *and* something is actually playing, and is
      killed the moment either stops — not left running at a lower frame rate
- [ ] Ask cava for few bars and a modest frame rate; the card is small
- [ ] Measure it. `intel_gpu_top` with the card open, and again with it closed, and write
      both numbers into PLAN.md next to the existing idle measurement. If it costs more
      than it is worth, it comes out

### 7. Weather

**Decided:** a standalone crate in this repo, so the config stays self-contained.

`~/code/rust/deskdock/desktop/deskdock-weather` already does the work: IP geolocation, then
NOAA's hourly forecast. It is a library inside the deskdock workspace and speaks protobuf
to the firmware, so the shell cannot use it as-is.

- [ ] `weather/` crate here: the NOAA fetch and geolocation, no `deskdock-proto`, a
      `main.rs` that prints one JSON object
- [ ] `services/Weather.qml` — runs it on a long timer, caches the last good reading to
      disk so a cold start is not blank
- [ ] Note: NOAA is US-only, and the crate already errors outside the United States
- [ ] README: the crate needs `cargo build --release` once; say so

### 8. CPU and memory

`/proc/stat` and `/proc/meminfo`, read on a timer while the page showing them is open, and
not otherwise. No dependency, no daemon.

- [ ] `services/SysStats.qml`
- [ ] Ring per figure, in the same dial language as the volume and battery

### 9. Settings page

Only the settings that get changed often, and the ones that are a pain to change by hand.
Not a second copy of every dotfile. Clavis's shape: a navigation rail down the left, one
page at a time on the right, cards inside a page — drawn in our own glass, not theirs.

- [ ] Agree the page list before building any of it
- [ ] A window, not a popout: it is too big to hang off the bar
- [ ] Settings persist to JSON outside git, next to `colors.json`

## Later

- Make it look really nice
- Right-click a control-center tile to open its detail panel (Clavis does this)
- VPN tile — there is a ProtonVPN profile in NetworkManager already
