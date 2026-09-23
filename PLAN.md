# Quickshell rewrite plan

## Goal

Replace the glued-together desktop (waybar + swaync + rofi + wlogout + polkit-gnome)
with **one Quickshell shell** that shares one theme, one set of sizes, and one
animation style. That shared base is what makes it feel like one thing.

**Keep what works today:**

- Clean, transparent pills floating over the wallpaper, with Hyprland blur behind them
- Colors taken from the wallpaper (matugen)
- Your keybinds and workflow (scrolling layout, scrolloverview, hyprshot, cliphist, xremap, fcitx5)

**The dependency rule — self-contained, not dependency-free.** A fresh Arch install with
`quickshell` and our own binaries should run this shell, with nothing else to install.
Work QML can't do goes into a Rust binary committed here, and that binary may *absorb*
what it needs: vendoring and linking a C library like `libcava` is fine, because it ends
up inside something we ship. What is not fine is anything that makes you install and
maintain a second thing first — a QML plugin (needs `quickshell-git` and CMake), or a
language runtime like node or Python (an interpreter plus its whole package tree). Both
reference shells fail this test. See *Helper programs* for the detail.

**Not doing:** AI panels, screen recording UI, cloud upload, a dock, maps, a window
switcher. If a feature doesn't earn its space, it doesn't go in. (Weather, the
visualiser, a small settings window and CPU/memory dials were later added on request;
see todo.md.)

**Scope reversed 2026-09-22**, after reading both reference shells feature by feature:
**lyrics, a desktop layer, a sidebar drawer and a Quickshell lock screen are now in
scope**, as Phases 6–9. They were out because of cost and dependency creep. That
objection is answered by the rules written into each phase below — a budget and a
lifecycle for every one of them — not waived. Anything that can't meet its budget comes
back out.

---

## What to take from the two references

### Caelestia (`caelestia-dots/shell`), built for Hyprland

| Borrow | Skip |
| --- | --- |
| Panels that **grow out of the bar** they belong to, in the same glass color, so a popout looks like part of the bar | The C++ plugin (`Caelestia.*` imports). It needs `quickshell-git` and a CMake build |
| One motion language: the same curves and durations everywhere | The full-screen "drawers" surface with a border frame around the screen. It blurs a much bigger area and redraws more |
| Launcher with modes (apps / calculator / clipboard) | Dashboard, performance page, visualizer, the "nexus" settings app |
| OSD that slides in, then away | `caelestia-cli` dependency |
| Colors loaded live from a JSON file; blur set with `layerrule … ignore_alpha` | The GIF mascots (bongocat, dino) on the media and session screens |
| **Lock screen shape** (Phase 9): PAM auth, with media, notifications and weather as cards on the lock surface | Fingerprint and Howdy unlock — no hardware for either |
| **Desktop layer** (Phase 7): a clock and a small card set drawn on the background layer | Their full-screen background visualiser — it animates the whole screen behind whatever window is covering it |
| Battery warn levels that raise a real notification (`modules/BatteryMonitor.qml`) | `ddcutil` external-monitor brightness |

### Clavis (`StatIndet/quickshell`), built for niri only

It can't run on Hyprland: it uses niri IPC plus native C++ plugins. Use it for ideas only.

| Borrow | Skip |
| --- | --- |
| The **"Keystone" island**: one center pill that morphs to show media, volume or a new notification, then shrinks back | Cloud upload, recording, the weather map, the dock, the niri overview |
| Clean folder split: `common/` (theme), `services/` (system), `modules/` (UI). UI files never run shell commands | `keytop` / `key-cli` helper programs |
| matugen writes one `colors.json` that the shell watches | Native plugin build system — we use standalone Rust binaries instead (see below) |
| **Lyrics in the island and the media card** (Phase 6) | Their C++ `lyrics` plugin. A Rust helper does the same job |
| **Sidebar drawer** (Phase 8): notifications plus a small set of tools you can act in — timer, todo | Their 30-card weather sidebar, the trend charts, the AQI panes |
| **Desktop cards** (Phase 7): a drag-placed card grid on the background layer | The analog "cookie clock" — lovely, but its second hand animates under whatever window is covering the desktop |
| Per-metric hover detail rather than a wall of figures | The bezier curve editor, the settings search, i18n |

---

## What replaces what

| Today | After | Phase |
| --- | --- | --- |
| waybar | **Bar** | 1 |
| swaync popups + control center | **Notifications** + **Control center** | 2 |
| *(nothing)* | **Volume/brightness OSD** inside the center island | 2 |
| rofi apps (`Ctrl+Space`) | **Launcher**: apps | 3 |
| rofi clipboard (`Super+V`) | **Launcher**: clipboard (still backed by cliphist) | 3 |
| rofi calc (`Super+C`) | **Launcher**: calculator (`qs-calc`, ours) | 3 |
| wlogout | **Session menu** | 3 |
| polkit-gnome | **Polkit agent** (`Quickshell.Services.Polkit`) | 3 |
| waypaper + hyprpaper | **Wallpaper picker** (optional) | 4 |
| rofi process manager (`Super+O`) | keep rofi for now | – |
| **hyprlock** | **Lock screen** (`WlSessionLock`). Coupling is two lines — `hypridle`'s `lock_cmd` and one block of `hypr-unstick.sh`; stays installed as the rollback | 9 |
| **hypridle** | **keep**: the suspend/resume workarounds live there | – |
| cliphist daemons, xremap, fcitx5, portal, hyprshot | keep | – |

Everything the plan needs ships in the stable `quickshell` package (0.3.1 in
`extra`), checked against the v0.3.1 source: Hyprland, Pipewire, UPower +
PowerProfiles, Networking, Bluetooth, Notifications, Mpris, SystemTray, Polkit,
DesktopEntries, GlobalShortcut, IdleMonitor. **No `quickshell-git` needed.**

---

## The look (design rules)

- **Layout stays the same as waybar.** Floating top bar: height 38, gap 3 px top / 5 px sides, radius 16.
  - Left: power button, workspaces 1–5
  - Center: **island** (clock + now playing)
  - Right: tray, network, volume, battery, control center, power
- **Glass.** Every surface uses the matugen `surface` color at 40% alpha (same as waybar now).
  Hyprland blurs behind it. Text uses `on_surface`. The accent (`primary`) is used only
  for the active workspace, sliders and focus.
- **One set of tokens** in `common/Appearance.qml`:
  - radius: pill = full, panel = 20, list item = 12
  - spacing: 4 / 8 / 12
  - fonts: JetBrains Mono for text, FiraCode Nerd Font for icons (both already installed)
- **One motion set:** 150 ms hover, 250 ms open/close, 400 ms morph, all with the same easing curve.
- **Popouts attach to the bar**, each under the button it belongs to.
  No random floating windows.
- **Wallpaper change:** colors fade to the new palette over ~400 ms, with no restart.

### Visual gaps (recorded 2026-09-22)

What both reference shells have and this one doesn't, in the order they'd be worth
doing. This is the concrete content of todo.md's "make it look really nice". Every item
is pure QML unless marked — none of them needs a plugin.

| | Gap | Where they do it | Cost |
| --- | --- | --- | --- |
| 1 | ~~**State layer**~~ **done 2026-09-22** — `components/StateLayer.qml`, opacities as tokens in `Appearance` (`stateHover`/`stateFocus`/`statePress`/`stateActive`), adopted by `Button`, `CircleButton`, `ListItem`, `Pill`; their hand-rolled hover colours are gone and everything responds to press. **Ripple deliberately not taken** — the tint alone was the part that earned its place | Clavis `StateLayer.qml`, caelestia `StateLayer.qml` | Done. `Theme.glassHover` stays for `CalendarPage` and `MediaCard`, which still use it directly |
| 2 | **Swipe-to-dismiss notifications.** Drag a card sideways past a threshold and it goes | Clavis `notifications/DragManager.qml`, caelestia `dragThreshold` | Already named as missing in Phase 2. Slide, never fade — the `ignore_alpha` gotcha |
| 3 | **Shared-element page transitions.** Settings and hub pages hard-swap today | Clavis `PageTransitionLayer.qml`, `ElementMoveAnimation.qml` | Reuses the `TabStrip` idea: two numbers chasing one index |
| 4 | **A shape vocabulary past rounded rectangles.** Squircles, the M3 cookie/clover family | Both, via `qt6-m3shapes-git` | We can't take the plugin. `Shape` + a path generator gets the two or three shapes actually worth having. `RingGauge` and `WavyProgress` already prove the approach |
| 5 | **Concave fillet where the island meets the bar edge**, so it reads as grown-from-the-bar rather than floating | Clavis `Styles/Shared/AttachedEdgeCurve.qml` | `Shape`, static geometry, redraws only when the island resizes |
| 6 | **Album-art palette** for the media card only — cover art tints the card, not the whole shell | caelestia `imageanalyser.cpp` + `smartScheme`, Clavis `MediaPalette` | `qs-palette` helper on the `material-colors` crate. Runs once per track change |
| 7 | **Icon recolouring** so tray and app icons take the theme | caelestia `Colouriser.qml`, `ColouredIcon.qml` | `MultiEffect` colourization. Unblocked by the 2026-09-22 rule 4 revision — it is a one-shot recolour on a 22 px icon, not a per-frame effect |
| 8 | **Elevation tokens** — a shadow scale for small raised elements | caelestia `effects/Elevation.qml`, Clavis `StyledRectangularShadow.qml` | Also unblocked. Static shadows cost once; what stays out is blurring a surface Hyprland already blurs |
| 9 | **Metaball "blobs"** drifting behind the media card | caelestia `Blobs/shaders/blob.frag` | A `ShaderEffect` needs no plugin. It redraws continuously, so it lives or dies by rule 1's gate: on only while the card is open **and** playing, exactly like cava. Fine under that gate — and at 260 Hz, size the shader to the card, not the screen |

Not taking: mascot GIFs, the full-screen background visualiser, the border frame around
the screen, per-widget compositor blur regions.

## Performance rules

**Revised 2026-09-22. The priority is the look. Cost that reaches the screen is worth
paying; cost that doesn't is waste.** These rules used to read as "spend as little as
possible", which is why the shell is fast and also why it is plainer than both
references. They now read as one question asked of every effect:

> **Can the user see this right now? If not, it must not be running.**

That is the whole rule. The rest is how to apply it.

1. **A loop is allowed while it is on screen.** What is banned is a loop that outlives
   the thing it draws — an animation still ticking under a closed panel, behind a
   fullscreen window, or on an unmapped surface. Gate it on being visible, and tear it
   down when it isn't. `cava` is the model: on only while the card is open *and* audio
   is playing. Animate freely inside that gate.
2. **No polling** (`Timer` + `Process`) when a built-in service exists. Pure waste,
   nothing on screen to show for it. Unchanged.
3. **Closed panels are not loaded.** `LazyLoader`/`Loader`. Unchanged.
4. **Don't redraw what Hyprland already drew.** ~~No `MultiEffect`~~ — the old rule
   banned the type, which was too broad and blocked visual gaps 7–9 for no gain.
   Blurring a panel Hyprland is already blurring is duplicated work you cannot see, and
   stays out. Shadows, colourization and shader effects on things you *can* see are in,
   subject to rule 1 and to measuring them.
5. **Small separate layer windows** (bar, popout, OSD), not one full-screen surface.
   Two exceptions, both earned: the session menu and the lock screen (Phase 9) are
   full-screen because they *are* the screen, and neither is mapped while idle.
6. **Update at the rate a change is perceptible.** A clock showing minutes ticks per
   minute — a per-second timer behind a minute display is invisible work. A *visible*
   seconds hand or a progress bar is a different case and may tick as fast as it needs.
7. **The idle check still stands, and is now the main gate.** `intel_gpu_top` ~0% render
   with nothing on screen changing. "Idle" means the user is looking at a static shell,
   not that the shell is doing nothing while visibly animating.
8. **An always-mapped surface pays rent.** The bar is the only one today. The desktop
   layer (Phase 7) is the second and last. Everything else is built on demand and
   dropped after, the way `Settings.menuLive` and `Clipboard.live` already work.
9. **Budgets are about waste, not about totals.** A phase that burns CPU with nothing on
   screen is reverted. A phase that costs more *while you are looking at it* and looks
   better for it has done its job — record the number, the way the visualiser's 7% is
   recorded below, and keep it.

**The one hard multiplier: the panel runs at 260 Hz.** Every animation draws ~260
frames a second, so per-frame work costs about 4x what it would at 60 Hz (AGENTS.md).
This doesn't forbid anything; it decides *how* to build it. Prefer `Shape` over `Canvas`
for anything animated, keep per-frame bindings out of repeated delegates, and animate one
property rather than a chain of dependent ones.

Baseline to beat (measured 2026-09-15): the parts being replaced use
swaync 134 MB + waybar 92 MB + polkit-gnome 37 MB ≈ **263 MB RSS**, ~0.4% CPU.

### The visualiser's cost (measured 2026-09-17)

The audio visualiser is the one thing in the shell that redraws continuously, and it is
the worked example of rule 1: wired to be absent rather than idle. cava is
launched only while the media card is on screen *and* audio is playing, and killed the
moment either stops. Measured as a share of one core, media playing throughout:

| State | shell | cava |
| --- | --- | --- |
| Media card closed | 0.2% | not running |
| Media card open, bars drawing | 5.4% | 1.6–2.6% |

So it costs roughly **7% of one core while you are looking at it, and nothing at all
when you are not**. Noisy to measure — the figures move by a percent or two between
runs — but the shape is clear, and `pgrep cava` returns nothing with the card closed.

Worth knowing: the shell's own idle figure with a track playing wanders between 0.2%
and 2.7% with the card shut, which is more than the "0 frames rendered during 20 s
idle" recorded in Phase 1. That predates the visualiser; the island's track title is
the likely cause and has not been chased down.

---

## Folder layout

```
~/.config/quickshell/
├── shell.qml              # entry point: loads every module
├── PLAN.md
├── common/                # no UI, no system calls
│   ├── Theme.qml          # colors from matugen colors.json (live reload)
│   ├── Appearance.qml     # sizes, radius, fonts, animation timings
│   └── Icons.qml          # Nerd Font glyphs (all verified present in the font)
├── services/              # singletons that talk to the system
│   ├── Audio.qml          # volume, mute, devices       (Quickshell.Services.Pipewire)
│   ├── Power.qml          # battery, power profile      (Quickshell.Services.UPower)
│   ├── Network.qml        # wifi / wired                (Quickshell.Networking)
│   ├── Bluetooth.qml      # radio + paired devices      (Quickshell.Bluetooth)
│   ├── Media.qml          # now playing                 (Quickshell.Services.Mpris)
│   ├── Session.qml        # session menu (wlogout until Phase 3)
│   ├── Swaync.qml         # temporary bell bridge, deleted in Phase 2
│   ├── Notifs.qml         # phase 2: notification server, DND, history
│   ├── Brightness.qml     # phase 2: brightnessctl, driven by keybinds
│   └── Clipboard.qml      # phase 3: cliphist; only runs when the launcher opens
├── components/            # Pill, StyledText, Icon, Slider, Popout, Anim, CAnim
└── modules/
    ├── bar/               # Bar, Workspaces, Island, Tray, TrayMenu, status pills
    ├── notifications/     # phase 2
    ├── osd/               # phase 2
    ├── launcher/          # phase 3
    ├── session/           # phase 3
    ├── wallpaper/         # phase 4
    ├── desktop/           # phase 7: background layer — clock + cards
    ├── sidebar/           # phase 8: the right-edge drawer
    └── lock/              # phase 9: WlSessionLock surface and its cards
```

Rules:

- Only `services/` start processes. Modules may read Quickshell's built-in singletons
  (e.g. `Hyprland`, `SystemTray`) directly when no extra logic is needed.
- Imports look like `import qs.common`, with no `qmldir` files needed.
- **Never name a property `onSomething`.** QML reads it as a signal handler. That's why
  matugen's `on_surface` is `Theme.surfaceText`, and `error` is `Theme.critical`.

### Helper programs: prebuilt Rust binaries. Not plugins, not runtimes

**The rule is self-contained, not dependency-free.** Work QML can't do goes into a Rust
binary committed here, and that binary is allowed to *absorb* what it needs. What it may
not do is make you install and maintain something else first.

The line is between a **library** and a **runtime**:

- **A C or C++ library is fine.** Vendor the source and link it statically, or link the
  system copy when one is there. The standard Rust shape for this is a `-sys` crate that
  probes with `pkg-config` and falls back to building the vendored source under a
  `vendored` cargo feature — `openssl-sys`, `libgit2-sys` and `zstd-sys` all work this
  way. Either path ends in one binary we ship. `libcava` is the example: fold it in, and
  nobody has to install it.
- **A language runtime is not.** Node or Python means shipping an interpreter *and* its
  package tree, and then keeping both working across upgrades. Unbounded, and it never
  ends in one binary. This is the reason no JS library goes in even though QML runs JS
  natively — the cost isn't the engine, it's npm and a lockfile to vendor and update.
- **Someone else's standalone binary is fine** when it is statically linked and has no
  ecosystem behind it. `matugen` qualifies: it is itself a Rust binary, not a runtime.
- **Free of charge: anything `quickshell` already links.** It pulls in
  `libpipewire-0.3.so.0` and `libwayland-client.so.0` (checked with `ldd`), plus Qt. A
  helper that links those adds nothing that wasn't already required.

Measured against that, both reference shells fail — caelestia needs `quickshell-git`
plus a CMake build before it starts at all, and then `caelestia-cli`, `fish`, `libcava`,
`aubio`, `lm_sensors`, `ddcutil`, `libqalculate` and a patched `qt6-m3shapes`; Clavis
needs twelve C++ plugins and niri. **The test here is: a fresh Arch install with
`quickshell` and our binaries runs the shell.** Nothing else to install.

Not a QML plugin either, whatever the language — that is what drags in `quickshell-git`
and CMake, and it is the single thing that makes caelestia unmovable.

`weather/` is the pattern and it holds up. The rules it set:

- **Prefer one shot, no daemon.** Three requests and exit. Blocking `reqwest`, so there
  is no async runtime inside a program that lives for 300 ms.
- **`rustls`, not the system OpenSSL**, so the binary survives an openssl bump. Vendor or
  statically link anything else it needs.
- **Use the crate, don't hand-roll it.** LRC parsing, FFT, Material colour extraction and
  expression evaluation are all solved (see the table). A helper should be glue.
- **`strip = true`, `opt-level = "s"`** in the release profile.
- **Cache the last good answer to `~/.cache/quickshell/`** so a cold start isn't blank
  and a failed fetch degrades to stale rather than empty.
- **The shell must work with the binary missing.** The feature goes quiet; nothing
  breaks. A missing helper is a normal state, not an error path.

**Two shapes, and picking the wrong one costs more than writing the thing.** Most
helpers are one-shot. An *interactive* one — the launcher's fuzzy matcher — must not be:
spawning a process per keystroke is worse than doing it badly in QML. That one is a
**long-lived worker**: queries in on stdin, ranked results out on stdout, one line each.
It lives exactly as long as its panel is open, started on open and killed on close, the
same lifecycle cava already has. No worker outlives the thing that needed it.

Planned helpers:

| Binary | Shape | Phase | Job, and what it builds on (crate versions checked 2026-09-22) |
| --- | --- | --- | --- |
| `qs-weather` | one-shot | done | Forecast. `reqwest` + `serde_json` + `chrono` |
| `qs-lyrics` | one-shot | 6 | LRCLIB fetch, timed-LRC parse, cache per track. **Don't write the parser** — `lrc`, `lrc_rs` or `lrc-nom` all do it |
| `qs-palette` | one-shot | visual gap 6 | Tint from cover art. `material-colors` is a current port of material-color-utilities — the same algorithm matugen uses. QML can't sample a decoded image |
| `qs-search` | **worker** | 3 | Fuzzy match over desktop entries, per keystroke. Replaces the JS matcher both references use |
| `qs-calc` | worker | 3 | Expression + unit evaluation. `evalexpr` is pure Rust; **there is no Rust binding for libqalculate**, and it is C++, so binding it is the expensive path. Start with the crate and only reach for the library if units and currency fall short |
| `qs-cava` | worker | later | Spectrum, replacing the `cava` process. See below |

Turn `weather/` into a Cargo workspace (`tools/`, one crate per binary) when the second
one lands, so there is one `cargo build --release` and one `target/`.

**The rule is about what the running shell needs, not what the repo contains.**
`dev/preview.sh` and `dev/mirror.py` are Python and stay that way — they never run on
the daily machine, and the preview harness is a development tool like `cargo` itself.
The test is whether a fresh Arch install with `quickshell` and these binaries runs the
shell, not whether the repo is single-language.

**External programs still in use, and the direction of travel.** The rule above is where
this is going, not where it already is. Today the shell runs `cava`, `cliphist`,
`brightnessctl` and `matugen`. Ranked by what absorbing each would cost:

| Program | Verdict |
| --- | --- |
| `matugen` | **Keep.** Already a static Rust binary with no ecosystem behind it — it passes the rule as-is |
| `brightnessctl` | **Cheapest to absorb.** It is a read and a write to backlight sysfs, plus a setuid/logind path for permission. `Brightness.qml` already watches `actual_brightness` itself |
| `cava` | **Absorb as `qs-cava`** when the visualiser is next touched. Note the trap: **Arch's `cava` package ships only the binary — no `.so`, no headers, no `.pc`** (checked with `pacman -Ql`), so "link the system libcava" is not available here. caelestia's `libcava` is a separate AUR fork. Two honest paths: vendor that fork's source and static-link it, or skip C entirely — capture through the `pipewire` crate (libpipewire is already linked by quickshell, so it is free) and bin the spectrum with `rustfft`/`realfft`. The second is more code and fewer moving parts; prefer it unless the output looks worse than cava's smoothing |
| `cliphist` | **Lowest priority.** It is a Go binary with its own on-disk store; reimplementing means owning that format. `services/Clipboard.qml` already documents its `delete`-from-stdin quirk. Leave it until something else forces the issue |

What matters meanwhile: **no new feature adds a new external program.** If it needs one,
it needs a crate instead.

---

## Theme pipeline

**Today:** waypaper `post_command` runs wal → pywalfox → matugen (hypr, swaync,
Claude theme) → crops an image for rofi → `killall -SIGUSR2 waybar`.
waybar, swaync and rofi read **pywal** colors while Hyprland reads **matugen**
colors. That means two different palettes, which is part of why things feel glued together.

**New:**

1. Add a matugen template `quickshell-colors.json` (same format as the existing
   `hyprland-colors.json`). Output it to `~/.local/state/quickshell/colors.json`,
   outside git, so it doesn't show up as modified like `hypr/colors.conf` does now.
2. `Theme.qml` watches that file (`FileView { watchChanges: true }`). Colors update
   live, with no signal or restart.
3. The shell uses **matugen only**. Keep `wal` just for pywalfox (Firefox) and the rofi process menu.
4. Remove the old steps as each phase lands: SIGUSR2 waybar (1), swaync template (2), rofi image crop (3).

---

## Hyprland integration

- **Autostart** (at cut-over): `exec-once = qs -d -n`. `-d` detaches from the terminal; `-n` refuses to start a second copy.
- **Blur** for all shell surfaces (namespaces start with `qs-`), in `hypr/conf/windows/decoration.conf`.
  Layer rules only apply when a surface is created, so restart the shell after changing them.

  ```
  layerrule = blur on, match:namespace ^(qs-.*)$
  layerrule = ignore_alpha 0.1, match:namespace ^(qs-.*)$
  ```

- **GPU:** `shell.qml` sets `__EGL_VENDOR_LIBRARY_FILENAMES` to Mesa only, so the shell never
  loads NVIDIA's EGL libraries (saved ~95 MB) and renders on the Intel iGPU.
- **Keybinds** use Hyprland global shortcuts, which are instant and don't spawn a process:

  ```
  bind = CTRL, space, global, qs:launcher
  bind = SUPER, V,     global, qs:clipboard
  bind = SUPER, C,     global, qs:calc
  ```

  Scripts can use IPC instead: `qs ipc call <target> <function>` (`qs ipc show` lists them).
- **Brightness keys go through the shell** (`global, qs:brightnessUp`). The shell runs
  brightnessctl and shows the OSD. The kernel doesn't send file-change events for
  backlight files, so this avoids polling.
- `Super+Shift+B` restarts the shell (bound in `hypr/quickshell.conf`).

---

## Phases

Every phase follows the same loop: **build → use it daily for a few days → remove the old
tool from autostart → commit.** Rolling back means re-enabling one `exec-once` line.

### Phase 0: Foundation ✅ (2026-09-15)

- [x] `sudo pacman -S quickshell` (0.3.1)
- [x] `shell.qml`, `common/` (Theme, Appearance, Icons), `components/` (Pill, StyledText, Icon, Anim, CAnim, Popout, Slider)
- [x] matugen template + `config.toml` entry; seeded `~/.local/state/quickshell/colors.json` from `hypr/colors.json`
- [x] Blur layer rules
- [x] Tested with `qs -p ~/.config/quickshell`: loads with no warnings, blur works, and editing
      `colors.json` recolors the bar live (verified by swapping `primary` and back)

### Phase 1: Bar (replaces waybar) ✅ cut over

- [x] Power button (opens wlogout until Phase 3)
- [x] Workspaces 1–5, always shown (more appear if they exist). Active grows, highlight slides; empty dimmed, urgent red. Click to switch, scroll to cycle
- [x] Island: rolling clock (each digit is a 0-9 strip on a spring; hours in text color, minutes in the accent, dot colon), click it for the date. The track title slides in when something is playing and flips over when the track changes (click = play/pause, scroll up = previous, down = next; paused = dim italic). Hovering it expands the island into the media card. The pill morphs springy open, calm closed — the Clavis "Keystone", themed as glass. No album art in the bar itself; it belongs to the card
- [x] Tray with menus drawn in the shell's style (checkboxes, radios, icons, submenus)
- [x] Volume: scroll ±2%, right-click mute, middle-click pavucontrol, left-click popout (slider, output devices, "Open mixer")
- [x] Network: wifi strength icon + name, wired, disconnected in red. Click opens nmtui
- [x] Battery: a ring dial in the same style as the volume, charge in the ring, icon in the middle; warning/critical colors, charging icon, percentage and status in the tooltip
- [x] Power profile: icon + color per profile; click cycles *(folded into the control center in Phase 2)*
- [x] Notification bell: count badge, click for the list, right click for do-not-disturb
      (the `swaync-client -swb` bridge is gone, along with `services/Swaync.qml`)
- [x] Use it daily for a few days (tray is the part to watch: two tray hosts can conflict while waybar also runs)
- [ ] *(later)* tooltips; clock calendar popout

Verified on 2026-09-15: volume popout and tray menu render correctly; **0 frames rendered
during 20 s idle**; dGPU stays suspended. Memory: 323 MB RSS / 181 MB PSS (83 MB private).
This is more than waybar alone (95 MB RSS), mostly shared Mesa/LLVM pages plus Qt Quick. The
shell absorbs swaync (134 MB) in Phase 2, so the combined total should come out lower.

**Cut-over ✅:** remove `exec-once = waybar` (autostart.conf), `killall -SIGUSR2 waybar` from the
waypaper `post_command`, the waybar layerrule; add `exec-once = qs -d -n`. Rebind
`Super+Shift+B` to `qs kill; qs -d -n`.

### Phase 2: Notifications + OSD (replaces swaync) ✅ cut over
>
> Stop swaync before testing. Only one notification daemon can run at a time.

- [x] Notification service (`services/Notifs.qml` + `NotifEntry.qml`): actions, images, app
      icons, urgency, same timeouts as before (4 s / 2 s low / 6 s critical). Entries are
      copied out of the server object, so an entry outlives the app that sent it, and
      `keepOnReload` plus adoption of tracked notifications means a config reload doesn't
      wipe the list. DND survives reloads. Popups are held back while DND is on or while
      something is fullscreen on the focused monitor; they still land in the list
- [x] Popups: stacked under the right end of the bar, slide in from the edge and leave the
      same way, the stack closing up behind them. Click runs the app's default action,
      right or middle click throws it away. *(no swipe yet)*
- [x] Notification list under the bell, with do-not-disturb and clear-all
- [x] Grouping by app in the notification list
- [x] Control center, under its own button: the brightness slider (plus a backlight picker
      when there is more than one panel) and the three power profiles as chips. It takes
      the place of the brightness and power-profile buttons — two seats on the bar for
      things you set rather than watch. The button keeps what they told you at a glance:
      the ring is the backlight, the tint is the profile. Volume keeps its own button, and
      the media card belongs to the island
- [x] Quick toggles in the control center: Wi-Fi, Bluetooth, microphone, do not disturb,
      each a tile saying what it is doing right now. A tile is a switch; the detail stays
      under the button that owns it (networks under the network icon, the mic level under
      the volume one). Bluetooth has no such button, so its paired devices are listed here,
      connecting and disconnecting on a click
- [x] Wifi list with connect (replaces the nmtui click): saved networks, password entry
      with the failure reason, forget
- [x] OSD: the island morphs to show volume or brightness when it moves, then shrinks back
      after 1.6 s. Driven by the values rather than by the keybinds, so it covers the laptop
      keys, the bar's own wheels and anything else running wpctl or brightnessctl
- [x] ~~Route brightness keys through the shell~~ — not needed. sysfs *does* raise change
      events on `actual_brightness`, so the shell watches the file and stays honest however
      the level moved
- [ ] *(optional)* island briefly shows a new notification's title

**Cut-over ✅:** remove `exec-once = swaync`, the swaync matugen template, the old
`layerrule2` swaync lines in `window_rules.conf`.

### Phase 3: Launcher, session menu, polkit (replaces rofi, wlogout, polkit-gnome)
>
> The app launcher and calculator stay on rofi for now — you asked to keep it.
> Clipboard history moved to the shell as its own window.

- [ ] Launcher in the center of the screen: fuzzy search over apps with icons, `Ctrl+j/k` navigation like your rofi. Matching goes through the `qs-search` worker (see the helper rules) — started when the launcher opens, killed when it closes
- [ ] Wallpaper image header, like your rofi theme. It reads the wallpaper path directly, so the `magick` crop step goes away
- [x] Clipboard: cliphist history on `Super+V` (`qs:clipboard`), with image previews and
      HTML entries shown as plain text — its own window rather than a launcher mode
- [ ] Calculator mode, through the `qs-calc` worker rather than `qalc` — a crate instead
      of a system package, per the dependency rule
- [x] Session menu: the same six actions, order, keys (l r s e u h) and commands as
      `wlogout/layout`, as a full-screen 3x2 grid of glass tiles whose icon swells on
      hover. Escape or a click outside closes it; arrows and Enter work too
- [x] Polkit password dialog in the shell's style (`services/Polkit.qml` + `modules/polkit/`).
      A click outside never cancels it, so a half-typed password survives; Escape does

**Cut-over:** remove the polkit-gnome `exec-once` line and the rofi image step in waypaper.
rofi stays only for `process.sh`.

### Phase 4: Wallpaper (optional)

- [ ] Picker panel: thumbnail grid of `~/Pictures/wallpaper`, newest first
- [ ] Picking one runs `scripts/set-wallpaper.sh` (hyprpaper → wal/pywalfox → matugen)
- [ ] Keep **hyprpaper** as the backend. First make sure scrolloverview's overview still shows the wallpaper if the shell ever draws it instead

**Cut-over:** remove `waypaper --restore`; the shell restores the last wallpaper.

### Phase 5: Polish

- [x] Island expands on hover: media controls + progress bar (done in Phase 1; the card
      takes no focus grab, so a hover panel never swallows a click)
- [ ] Material Symbols Rounded icons instead of Nerd Font glyphs
- [ ] ~~Lock screen in Quickshell~~ — **superseded; it is now Phase 9.** Until that
      lands hyprlock stays, and the session menu's Lock goes through
      `loginctl lock-session` so hypridle's handling still applies

Three small items promoted here from the 2026-09-22 comparison, because each is a gap in
something already built rather than a new panel:

- [x] **Battery warnings.** `services/Power.qml` shows the charge and never says
      anything about it. Add warn levels (20% low, 10% critical, and a "charger pulled
      while under 15%" case), each raising a real notification through the existing
      server. Event-driven off the UPower percentage — **no timer**: the level crossings
      are computed in the change handler, and a flag per threshold stops it re-firing as
      the reading jitters across the line. Reset the flags on charge. Suppress entirely
      while charging.
- [x] **Workspace dots say what is in them.** Hovering a dot currently says nothing.
      Show the workspace's windows — app icon plus title — in the existing `Tooltip`.
      Performance shape matters here: `Workspaces.qml` is a `Repeater`, and AGENTS.md's
      rule is that per-frame bindings stay out of repeated delegates. So the window list
      is built **on hover only**, in a handler, from `Hyprland.toplevels` filtered by
      workspace — not a binding that every delegate re-evaluates whenever any window
      moves. One shared `Tooltip` for the row, repositioned, rather than one per dot.
      Checked against 0.3.1's qmltypes: a toplevel gives `title` and `workspace`
      directly, but **no `class` property** — the app id for the icon comes off
      `lastIpcObject.class`, then through `DesktopEntries`, the same lookup `Tray` does.
- [x] **Finish the OSD morph's motion.** The island's half is already done and good:
      `Island.qml` eases `osdProgress` with `curveExpand`/`curveShrink` and cross-fades
      the media chip out. Three things inside it still snap, and the bar outside it
      doesn't react at all:
      - the **value** jumps between steps — `osdValue` feeds the slider and the
        percentage with no `Behavior`, so a held volume key reads as a stack of
        2% jerks rather than a sweep
      - the **glyph** swaps instantly when the kind changes under a live OSD (volume
        → brightness), and the mute colour flips with it
      - the **bar pill that owns the value** — Volume, or the control-center button for
        brightness — gives no sign it is the thing being changed. A brief accent tint on
        that pill for as long as the OSD is up makes the bar read as one object
        reacting, which is the whole point of the island
      Constraints: one-shot per change, comfortably finished inside the 1.6 s before
      `Osd` clears. **Leave the side groups edge-anchored.** They do not reflow today
      (`Bar.qml` anchors them left and right while the island is centred), and making
      them slide would move every `Popout` target — `anchorX` re-reads `target.x` and its
      parents for exactly this reason (AGENTS.md), so an animated group `x` would have
      popouts chasing the OSD across the bar.

      **Done 2026-09-22**, except the bar-pill tint, which is still open. Plus one thing
      this list didn't anticipate: a fullscreen window covers the bar, so the island's
      morph can't be seen at all. The OSD now gets its own surface in that case —
      `modules/osd/OsdWindow.qml`, overlay layer, focused monitor only,
      `mask: Region {}` so it never eats a click — built behind `Osd.overlayLive` and
      absent the rest of the time. `Osd.muted`/`value`/`icon` moved into the singleton
      for the two surfaces to share; the *eased* reading stayed in each surface, since a
      service importing `qs.components` for `Anim` would put a singleton on top of the
      UI layer.

---

### Phase 6: Lyrics

Smallest of the four new phases, and it feeds the three after it — the lock screen and
the desktop layer both want a lyrics card, so this comes first.

- [ ] `tools/qs-lyrics` — Rust binary per the helper rules above. Takes artist/title/
      album/duration, hits LRCLIB, prints JSON lines of `{ ms, text }`. Caches per track
      under `~/.cache/quickshell/lyrics/`, so a re-listen makes no request at all.
      **Use an LRC crate** (`lrc`, `lrc_rs` or `lrc-nom`) rather than writing the parser —
      the A2 extension and the malformed-timestamp cases are where hand-rolled ones break
- [ ] `services/Lyrics.qml` — runs it **once per track change**, never on a timer.
      Holds the parsed lines and the current index. No network work while a track plays
- [ ] The current-line index advances from the same 1 Hz position timer `MediaCard.qml`
      already runs, which itself only runs while the card is active and playing. No
      second timer, and nothing ticking with the card shut
- [ ] Media card: lines scroll with the current one highlighted. Hub media tab gets the
      taller version
- [ ] Island: **not** a lyrics mode. Clavis has one; it would mean the island re-lays out
      every few seconds all through a track, which is rule 1 in everything but name
- [ ] Instrumental tracks, tracks LRCLIB doesn't have, and a missing binary all look the
      same: no lyrics pane, no error, no retry loop

**Budget:** zero measurable cost with the media card closed (`pgrep qs-lyrics` finds
nothing), and no increase in the card-open figure beyond noise — the 1 Hz timer already
exists, this only adds what it does per tick.

### Phase 7: Desktop layer

A background-layer surface holding a clock and a few cards. This is the **second and
last** always-mapped surface (performance rule 8), so its budget is the tight one.

- [ ] `modules/desktop/` on `WlrLayer.Background`, namespace `qs-desktop`, one
      `PanelWindow` per screen through `Variants`
- [ ] Draws **above hyprpaper, not instead of it.** Decision 3 stands: hyprpaper keeps
      the wallpaper, so scrolloverview's overview is unaffected. Revisit only in Phase 4
- [ ] Clock and date, in the island's digit language. **Per-minute updates** (rule 6)
- [ ] A small card set, on the same reader-counted services the hub already uses:
      weather, CPU/memory, calendar. A card that needs a service subscribes while it is
      on the desktop, exactly as `SysStats.readers` works now
- [ ] Cards are placed on a coarse grid, dragged to move, position saved to
      `settings.json`. Clavis's `DesktopCardCanvas` is the shape to copy, minus the
      wallpaper analysis
- [ ] **Static by default — because the desktop is usually covered.** This is rule 1,
      not an aesthetic preference: a second hand or a drifting shape down here is
      animating under a full-screen window nearly all the time, which is the exact
      shape of cost the revised rules still reject. Animate on hover, on wallpaper
      change, and on the transitions in and out. If a cheap "is the desktop actually
      exposed" signal turns up (an empty workspace, the overview), a gated continuous
      animation becomes fair game — the gate is the requirement, not the stillness
- [ ] Layer rules: `qs-desktop` matches the existing `^(qs-.*)$` blur rule, which is
      probably wrong for a background surface — blurring the wallpaper under a desktop
      card is both invisible and expensive. Add an explicit `blur off` for this one
      namespace and check it against `ignore_alpha 0.1`
- [ ] The whole layer is optional and off by default, behind a Settings toggle, built
      through a `LazyLoader` like every other panel

**Budget:** `intel_gpu_top` still ~0% with the desktop visible and the cursor away from
it, and no more than +15 MB RSS. Miss either and it reverts (rule 9). Measure with the
bar's own idle figure as the control.

### Phase 8: Sidebar drawer

**Most of this already exists** — that was the finding on 2026-09-22. The notification
list, grouping, DND and clear-all are built (`modules/bar/NotifCenter.qml`), and so is a
four-tab hub (`modules/dashboard/`). What's missing is a place to *act*: every panel in
this shell today is read-only.

So this phase is mostly a re-home plus two new tools, not a new subsystem.

- [ ] A right-edge drawer, `modules/sidebar/`, namespace `qs-sidebar`. Opens from the
      bell, from a bar edge gesture, and from a global shortcut (`qs:sidebar`)
- [ ] Move the existing notification list into it unchanged. `NotifCenter.qml`'s popout
      stays as the quick look; the drawer is the long one
- [ ] Swipe-to-dismiss on the cards here and in the popups (visual gap 2). **Slide, never
      fade** — the `ignore_alpha 0.1` rule smears a fading card's blur region
- [ ] **Timer** and **todo list**, the two tools from Clavis's `infoTools/` that earn
      their space. A todo is a JSON list in `~/.local/state/quickshell/`. A running timer
      is the one thing in this shell allowed to tick per second, and only while the
      drawer is open — when it's shut the end time is a stored timestamp and a single
      `Timer` set to fire once, so a closed drawer costs nothing and the alarm still lands
- [ ] Not taking: the weather trend charts, the AQI panes, the profile header, the drawer
      grid. If a page needs a scrollbar it is doing too much — todo.md's rule, still good
- [ ] `LazyLoader` off a `Sidebar.live` count, with the linger timer a little longer than
      `Appearance.animNormal`, exactly as `Settings.menuLive` does. **Never** key
      `active` off `item.progress` (AGENTS.md)
- [ ] **Fixed width and height.** A blurred layer surface that resizes stutters, and a
      shrinking one leaves the ghost band documented in todo.md §10

**Budget:** nothing running with the drawer closed except a pending one-shot timer.

### Phase 9: Lock screen (replaces hyprlock)

The biggest and the riskiest, so it goes last. A lock screen that fails locks you out of
your own session, and hyprlock is currently load-bearing beyond locking.

> **The blocker was smaller than it looked.** Traced 2026-09-22. The earlier note here
> claimed the resume fix was built around hyprlock and that hypridle called it directly.
> Checked against the actual config, hyprlock is referenced in exactly **two live
> places**, and one is a manual script:
>
> - `hypridle.conf:2` — `lock_cmd = pidof hyprlock || hyprlock`. This is the real one.
>   The 10-minute listener runs `loginctl lock-session`, and logind's Lock signal is what
>   reaches `lock_cmd`. **Open question to settle first:** the shell must answer that
>   signal itself. `WlSessionLock` sets the lock state, but nothing in 0.3.1 obviously
>   listens to `org.freedesktop.login1`'s `Lock` — check whether that needs a D-Bus
>   watcher before anything else is built, because without it the lock never arms.
> - `hypr-unstick.sh`'s last block — kills and restarts hyprlock when a lock client's GL
>   context dies across suspend. **Nothing calls this script**; it is run by hand from a
>   TTY. With a Quickshell lock, that block becomes `qs kill; qs -d -n` instead. One
>   rewrite of a recovery path, not a dependency.
>
> The suspend/resume workarounds in `hypridle.conf` (`before_sleep_cmd`,
> `after_sleep_cmd`, `hypr-post-resume.sh`) are **already commented out**, which supports
> the 2026-09-22 read that the underlying Hyprland bug is fixed — the machine is on
> 0.56.2 (Aug 2026) and the grey screen was diagnosed 2026-07-30. Not re-verified here;
> confirm with one suspend/resume cycle before starting, since it is free to check.

- [ ] `WlSessionLock` in `modules/lock/`. The compositor holds the session locked even
      if the shell crashes, which is the property that makes this safe to attempt at all
- [ ] PAM through Quickshell's own auth. Password only — no fingerprint, no Howdy
- [ ] **Keep hyprlock installed and configured throughout.** Cut-over means changing what
      `loginctl lock-session` reaches, and rolling back is putting that line back. Do not
      remove the hyprlock config in the same commit that adds the lock screen
- [ ] Cards on the lock surface, reusing what exists: clock, media (with Phase 6 lyrics),
      notifications, weather. Same components, not copies
- [ ] Notification content on the lock surface is **hidden by default** — summary and app
      only, bodies behind an unlock. A lock screen that reads out your messages to the
      room is worse than no lock screen
- [ ] Multi-monitor: every screen gets a surface, input on one, the others dimmed
- [ ] Test in a nested compositor first, then a TTY with a second one open, then for real
      **with a root shell already logged in on another VT**

**Budget:** zero while unlocked — the surface is built on lock and destroyed on unlock,
so `qs` idle figures must be unchanged. Rule 5's full-screen exception applies only
because of that.

---

## Everyday workflow

| Task | Command |
| --- | --- |
| Run while developing (live reload, logs in terminal) | `qs -p ~/.config/quickshell` |
| Logs of the running shell | `qs log -f` |
| List IPC functions | `qs ipc show` |
| Restart | `qs kill; qs -d -n` |
| Memory / CPU | `ps -o rss,pcpu -C quickshell` |
| Idle redraw check (should be ~0%) | `intel_gpu_top` |
| Battery draw, on battery power (µW) | `cat /sys/class/power_supply/BAT*/power_now` |

Commit once per phase in the `~/.config` repo.

---

## Decisions (1–3 settled before Phase 1; 4–6 are open)

1. **Bar position:** keep the top floating bar *(default)*, or switch to Caelestia's
   left vertical bar with a frame around the screen (costs more blur area).
2. **Center island:** yes *(default)*, since it replaces a separate OSD window. The
   alternative is a plain clock + media pill.
3. **Wallpaper backend:** keep hyprpaper *(default)*, or have the shell draw the
   wallpaper (enables crossfades, but needs the overview check first). Phase 7's desktop
   layer draws *above* hyprpaper, so it does not force this either way.

### Open, from the 2026-09-22 comparison

4. ~~**Does performance rule 4 mean "no `MultiEffect`" or "no blur over a blurred
   surface"?**~~ **Settled 2026-09-22: the second.** The whole performance section was
   re-based on "cost that reaches the screen is worth paying" — see the rules above.
   Visual gaps 7–9 are unblocked.
5. **Is the desktop layer on by default?** Proposed no: off, behind a Settings toggle.
   It is the only feature here that can cost something while you are not looking at it,
   which is the one thing the revised rules still care about.
6. ~~**Lock screen fallback**~~ — **largely settled**, see the note in Phase 9. The
   hyprlock coupling is two lines, one of them in a hand-run script, and the resume bug
   it guarded against appears fixed upstream. What remains open is narrower and
   technical: **does the shell need its own logind `Lock` D-Bus watcher to answer
   `loginctl lock-session`?** Settle that before building the surface.
