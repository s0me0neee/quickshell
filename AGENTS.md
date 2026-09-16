# AGENTS.md

A single **Quickshell** shell (QML) that replaces waybar, swaync, wlogout and friends on
Hyprland. This is **not a compiled project** — Quickshell loads and live-reloads the QML
directly. There is no build step, no test suite, and no linter.

The authoritative design/roadmap doc is `PLAN.md`. Read it before large changes; it
states hard performance rules, the theme pipeline, and what is explicitly *not* in scope.

## Commands

| Task | Command |
|---|---|
| Run while developing (live reload, logs in terminal) | `qs -p ~/.config/quickshell` |
| Tail the running shell's logs | `qs log -f` |
| Restart (e.g. after changing Hyprland layer rules) | `qs kill; qs -d -n` |
| List / call IPC functions | `qs ipc show` · `qs ipc call <target> <fn>` |
| Memory / CPU | `ps -o rss,pcpu -C quickshell` |
| Idle redraw check (target ~0%) | `intel_gpu_top` |
| Preview without Hyprland (see below) | `./dev/preview.sh [--shot foo.png] [--scenario ...]` |

Editing any `.qml` file reloads the shell immediately. There is no build to run.

## Architecture

```
shell.qml            entry point: loads every module
common/              Singletons, no UI and no system calls
components/          reusable widgets (Pill, CircleButton, Popout, Icon, ...)
services/            Singletons that talk to the system
modules/bar/         the bar and everything in it
modules/notifications/  popups + notification list
modules/session/     the full-screen session menu
dev/                 off-machine preview (stubs for Quickshell, mock data)
matugen/             matugen colour template
hypr/                Hyprland snippet (blur rules, autostart, restart bind)
```

**Import convention:** `import qs.common`, `import qs.components`, `import qs.services`,
`import qs.modules.bar`. The part after `qs.` is the directory name; no `qmldir` files
are needed.

**Layering rules** (from `PLAN.md`, enforced by review not tooling):
- Only `services/` start processes. Modules read Quickshell's built-in singletons
  (`Hyprland`, `SystemTray`, etc.) directly when no extra logic is needed.
- No QML blur/shadows (`MultiEffect`) in production — Hyprland blurs via `layerrule`.
- No animation that loops forever; no polling when a built-in service exists.
- Closed panels are not loaded (wrap in `LazyLoader`/`Loader`).

## Conventions

- **Singletons** use `pragma Singleton` + `Singleton { id: root }` and expose
  `readonly property` + functions. See `services/Audio.qml` for the canonical shape.
- **Never name a property `onSomething`** — QML treats it as a signal handler. This is
  why matugen's `on_surface` becomes `Theme.surfaceText` and `error` becomes
  `Theme.critical`. `Theme.apply()` does the snake_case → camelCase rename.
- **Theme colours** live only in `common/Theme.qml`. `glass`, `glassHover`, `tonal`,
  `accent`, `panel`, `textDim` are derived there. Components take colours from `Theme`,
  sizes/motion from `Appearance`, glyphs from `Icons`.
- **Motion** is centralized in `Appearance.qml`: use `Anim { }` / `CAnim { }` from
  `components/` (default easing/duration) rather than raw `NumberAnimation`, and the
  shared `curveStandard`/`curveEmphasized`/`curveExpressive` lists.
- **`required property`** is used for injected dependencies (`bar`, `modelData`,
  `screen`, `target`). Repeater delegates must declare `required property var modelData`
  (or the typed equivalent) to receive their item.
- **Component-local sub-widgets** are declared with inline `component Foo: ...` at the
  bottom of the file (`Volume.qml`, `TrayMenu.qml`).

## Key data flow

- **Theme:** matugen writes `~/.local/state/quickshell/colors.json` (gitignored state,
  not config). `common/Theme.qml` watches it with `FileView { watchChanges: true }` and
  recolours the shell live. A fallback palette is hardcoded until matugen runs.
- **One popout at a time:** `common/PopoutState.qml` holds `current`. Every `Popout`
  sets `PopoutState.current = root` on open and closes itself via a `Connections` when
  `current` points elsewhere. Popouts hang below the bar and take `bar` + `target` as
  required properties.
- **Media** (`services/Media.qml`): pin players by **bus name**, never the object —
  holding the object showed a dead player's last track. `autoBus` only moves when a
  player *starts* (so pausing the shown player doesn't yank the bar to another app).
- **Notifications** (`services/Notifs.qml` + `NotifEntry.qml`): entries are copied out
  of the server object so they outlive the sending app. `keepOnReload` plus adoption in
  `Component.onCompleted` keeps the list across a config reload.
- **Audio** (`services/Audio.qml`): volume/mute are only valid on *tracked* nodes, so
  `PwObjectTracker { objects: [sink, source, ...streams] }` must include every node whose
  level is shown.

## Gotchas (non-obvious, learned the hard way)

- **`shell.qml` starts with `//@ pragma Env __EGL_VENDOR_LIBRARY_FILENAMES=...`.** This
  forces Mesa's EGL (Intel iGPU) and stops glvnd from loading NVIDIA's EGL libs (~95 MB).
  Do not remove or reorder that pragma.
- **Hyprland layer rules apply only when a surface is created.** After editing
  `hypr/quickshell.conf` blur/alpha rules, restart the shell (`qs kill; qs -d -n`).
- **Layer namespaces must start with `qs-`** for the blur `layerrule` to match
  (`WlrLayershell.namespace: "qs-bar"`, `"qs-popout"`, `"qs-session"`, `"qs-notifications"`).
- **A `Behavior` never runs on a binding's first evaluation.** To animate an item's
  *initial* state, declare the property as a plain `0` and bind it in
  `Component.onCompleted` with `Qt.binding(...)` (`SessionMenu.qml`, `Popups.qml`).
- **Animations inside a `Behavior` never emit `finished()`.** Use a `Timer` to sweep
  after they settle (`Popups.qml`'s `sweep` timer).
- **A `Repeater` on a plain array rebuilds every delegate when the array is reassigned.**
  Wrap in `ScriptModel { values: ... }` when the array changes often (`Popups.qml`).
- **`onOpenChanged` on a `Popout` subclass:** implement it with `Connections`, not a
  handler. A handler on the subclass root would overwrite `Popout`'s own `onOpenChanged`
  (which closes sibling popouts). See `Calendar.qml`.
- **Do not fade notification cards to opacity 0.** Hyprland's `ignore_alpha 0.1` rule
  skips sub-0.1-alpha surfaces, so a fading card smears the blur region every frame.
  Slide them instead (`Popups.qml`). The notifications window is also kept at a **fixed**
  size so resizing a blurred layer surface doesn't stutter.
- **No brightness polling:** backlight sysfs files raise no change events. `Brightness`
  re-reads on demand (panel open, device change) and debounces writes through a `Timer`.
- **MPRIS doesn't push position.** `MediaCard.qml` refreshes position once per second via
  a `Timer` that runs only while the card is active and playing.
- **`Icon.qml` centers by ink box, not the font box.** Nerd Font glyph boxes are uneven;
  it uses `FontMetrics`/`TextMetrics.tightBoundingRect`, never `Text.baselineOffset`.
  Use `nudgeX`/`nudgeY` for glyphs whose ink reads off-centre.
- **`Popout.anchorX`** computes the target's screen X by manually walking
  `target.x + parent.x + ...`; there is a leftover dead `return` beneath it. Don't rely
  on `mapToItem` for bar anchoring.

## dev/ preview (running without Hyprland)

`./dev/preview.sh` runs the *real* shell files under the plain `qml` tool against fake
Quickshell services in `dev/stubs/`. Needs Qt 6 + Python 3 only. Useful flags:
`--shot file.png` (offscreen render), `--scenario media,tray,notifs,session,...`,
`--open N` (open a popout by index; the run prints the list), `--width/--height`.

- `mirror.py` mirrors `*.qml` into `dev/.build/qs` (gitignored), adding a `qmldir` per
  directory since `qml` doesn't know directories are modules. Unchanged files are
  symlinked.
- The stubs must match Quickshell's declared types. Two recurring failures when a stub
  is wrong (see `dev/README.md`): *"Cannot assign to non-existent property"* (a grouped
  property declared `QtObject` needs a concrete stub type — hence `Anchors.qml`,
  `PopupAnchor.qml`) and *"Property 'filter' of object function values()"* (a stub
  returned a bare array where Quickshell returns an ObjectModel — return
  `({ values: [...] })` instead).
- In the mirror, `WlrLayershell.*` is commented out (C++ attached type, undeclarable in
  pure QML); `ClippingRectangle` clips to the bounding box not the rounded shape; fonts
  are rewritten to the macOS family name.
