# Quickshell rewrite plan

## Goal

Replace the glued-together desktop (waybar + swaync + rofi + wlogout + polkit-gnome)
with **one Quickshell shell** that shares one theme, one set of sizes, and one
animation style. That shared base is what makes it feel like one thing.

**Keep what works today:**

- Clean, transparent pills floating over the wallpaper, with Hyprland blur behind them
- Colors taken from the wallpaper (matugen)
- Your keybinds and workflow (scrolling layout, scrolloverview, hyprshot, cliphist, xremap, fcitx5)

**Not doing:** AI panels, weather, lyrics, desktop widgets/cards, audio visualizer
(cava), screen recording UI, cloud upload, a big settings app, a performance
dashboard. If a feature doesn't earn its space, it doesn't go in.

---

## What to take from the two references

### Caelestia (`caelestia-dots/shell`), built for Hyprland

| Borrow | Skip |
| --- | --- |
| Panels that **grow out of the bar** they belong to, in the same glass color, so a popout looks like part of the bar | The C++ plugin (`Caelestia.*` imports). It needs `quickshell-git` and a CMake build |
| One motion language: the same curves and durations everywhere | The full-screen "drawers" surface with a border frame around the screen. It blurs a much bigger area and redraws more |
| Launcher with modes (apps / calculator / clipboard) | Dashboard, performance page, visualizer, the "nexus" settings app |
| OSD that slides in, then away | `caelestia-cli` dependency |
| Colors loaded live from a JSON file; blur set with `layerrule … ignore_alpha` | Lock screen (you keep hyprlock, see below) |

### Clavis (`StatIndet/quickshell`), built for niri only

It can't run on Hyprland: it uses niri IPC plus native C++ plugins. Use it for ideas only.

| Borrow | Skip |
| --- | --- |
| The **"Keystone" island**: one center pill that morphs to show media, volume or a new notification, then shrinks back | Weather, lyrics, cava, desktop cards, cloud upload, recording, map |
| Clean folder split: `common/` (theme), `services/` (system), `modules/` (UI). UI files never run shell commands | `keytop` / `key-cli` helper programs |
| matugen writes one `colors.json` that the shell watches | Native plugin build system |

---

## What replaces what

| Today | After | Phase |
| --- | --- | --- |
| waybar | **Bar** | 1 |
| swaync popups + control center | **Notifications** + **Control center** | 2 |
| *(nothing)* | **Volume/brightness OSD** inside the center island | 2 |
| rofi apps (`Ctrl+Space`) | **Launcher**: apps | 3 |
| rofi clipboard (`Super+V`) | **Launcher**: clipboard (still backed by cliphist) | 3 |
| rofi calc (`Super+C`) | **Launcher**: calculator (qalc) | 3 |
| wlogout | **Session menu** | 3 |
| polkit-gnome | **Polkit agent** (`Quickshell.Services.Polkit`) | 3 |
| waypaper + hyprpaper | **Wallpaper picker** (optional) | 4 |
| rofi process manager (`Super+O`) | keep rofi for now | – |
| **hyprlock** | **keep**: `hypr-unstick.sh` and the resume fix depend on it | – |
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

## Performance rules (keep battery the same as today)

1. **No animation that loops forever.** Animate only when something changes.
2. **No polling** (`Timer` + `Process`) when a built-in service exists.
3. **Closed panels are not loaded.** Wrap them in `LazyLoader`/`Loader`.
4. **No blur or shadow effects inside QML** (`MultiEffect`). Let Hyprland blur.
5. **Small separate layer windows** (bar, popout, OSD), not one full-screen surface.
6. **Clock updates per minute**, not per second.
7. After every phase, check that `intel_gpu_top` shows ~0% render while idle.

Baseline to beat (measured 2026-09-15): the parts being replaced use
swaync 134 MB + waybar 92 MB + polkit-gnome 37 MB ≈ **263 MB RSS**, ~0.4% CPU.

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
    └── wallpaper/         # phase 4
```

Rules:

- Only `services/` start processes. Modules may read Quickshell's built-in singletons
  (e.g. `Hyprland`, `SystemTray`) directly when no extra logic is needed.
- Imports look like `import qs.common`, with no `qmldir` files needed.
- **Never name a property `onSomething`.** QML reads it as a signal handler. That's why
  matugen's `on_surface` is `Theme.surfaceText`, and `error` is `Theme.critical`.

### Native plugins

Locally built Rust plugins (e.g. via cxx-qt) are allowed, but only where QML is
genuinely slow or missing an API. The bar needs none. Likely first candidate: fuzzy
matching for the Phase 3 launcher, if plain JS search feels slow.

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
- `Super+Shift+B` stays "restart waybar" until Phase 1 is done. Then it becomes "restart shell" (`qs kill; qs -d`).

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

### Phase 1: Bar (replaces waybar) — built, waiting for daily use + cut-over

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
- [ ] Use it daily for a few days (tray is the part to watch: two tray hosts can conflict while waybar also runs)
- [ ] *(later)* tooltips; clock calendar popout

Verified on 2026-09-15: volume popout and tray menu render correctly; **0 frames rendered
during 20 s idle**; dGPU stays suspended. Memory: 323 MB RSS / 181 MB PSS (83 MB private).
This is more than waybar alone (95 MB RSS), mostly shared Mesa/LLVM pages plus Qt Quick. The
shell absorbs swaync (134 MB) in Phase 2, so the combined total should come out lower.

**Cut-over:** remove `exec-once = waybar` (autostart.conf), `killall -SIGUSR2 waybar` from the
waypaper `post_command`, the waybar layerrule; add `exec-once = qs -d -n`. Rebind
`Super+Shift+B` to `qs kill; qs -d -n`.

### Phase 2: Notifications + OSD (replaces swaync)
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
- [ ] Quick toggles in the control center: wifi, bluetooth, mic mute
- [ ] Wifi list with connect (replaces the nmtui click)
- [x] OSD: the island morphs to show volume or brightness when it moves, then shrinks back
      after 1.6 s. Driven by the values rather than by the keybinds, so it covers the laptop
      keys, the bar's own wheels and anything else running wpctl or brightnessctl
- [x] ~~Route brightness keys through the shell~~ — not needed. sysfs *does* raise change
      events on `actual_brightness`, so the shell watches the file and stays honest however
      the level moved
- [ ] *(optional)* island briefly shows a new notification's title

**Cut-over:** remove `exec-once = swaync`, the swaync matugen template, the old
`layerrule2` swaync lines in `window_rules.conf`.

### Phase 3: Launcher, session menu, polkit (replaces rofi, wlogout, polkit-gnome)
>
> The launcher and clipboard stay on rofi for now — you asked to keep it.

- [ ] Launcher in the center of the screen: fuzzy search over apps with icons, `Ctrl+j/k` navigation like your rofi
- [ ] Wallpaper image header, like your rofi theme. It reads the wallpaper path directly, so the `magick` crop step goes away
- [ ] Clipboard mode: cliphist list → pick → copy + auto-paste (same as `clipboard.sh`)
- [ ] Calculator mode (qalc)
- [x] Session menu: the same six actions, order, keys (l r s e u h) and commands as
      `wlogout/layout`, as a full-screen 3x2 grid of glass tiles whose icon swells on
      hover. Escape or a click outside closes it; arrows and Enter work too
- [ ] Polkit password dialog in the shell's style

**Cut-over:** remove the polkit-gnome `exec-once` line and the rofi image step in waypaper.
rofi stays only for `process.sh`.

### Phase 4: Wallpaper (optional)

- [ ] Picker panel: thumbnail grid of `~/Pictures/wallpaper`, newest first
- [ ] Picking one runs `scripts/set-wallpaper.sh` (hyprpaper → wal/pywalfox → matugen)
- [ ] Keep **hyprpaper** as the backend. First make sure scrolloverview's overview still shows the wallpaper if the shell ever draws it instead

**Cut-over:** remove `waypaper --restore`; the shell restores the last wallpaper.

### Phase 5: Polish (only if you want it)

- [x] Island expands on hover: media controls + progress bar (done in Phase 1; the card
      takes no focus grab, so a hover panel never swallows a click)
- [ ] Material Symbols Rounded icons instead of Nerd Font glyphs
- [ ] ~~Lock screen in Quickshell~~ — **not doing for now.** hyprlock stays; the session
      menu's Lock goes through `loginctl lock-session`, so hypridle's handling still applies

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

## Decisions (defaults chosen; change them before Phase 1 if you disagree)

1. **Bar position:** keep the top floating bar *(default)*, or switch to Caelestia's
   left vertical bar with a frame around the screen (costs more blur area).
2. **Center island:** yes *(default)*, since it replaces a separate OSD window. The
   alternative is a plain clock + media pill.
3. **Wallpaper backend:** keep hyprpaper *(default)*, or have the shell draw the
   wallpaper (enables crossfades, but needs the overview check first).
