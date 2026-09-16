# dev/ — running the shell without Hyprland

Quickshell only runs on Wayland, so on a Mac or any non-Linux machine there is no way to
see what a change looks like. This runs the *real* shell files under the plain `qml` tool
instead, against fake Quickshell services. Nothing in the shell itself is aware of it.

```sh
./dev/preview.sh                      # open it in a window
./dev/preview.sh --shot bar.png       # render it offscreen to a file
./dev/preview.sh --scenario notifs    # choose what the fake services report
```

Needs Qt 6 (`brew install qt`) and Python 3. No Quickshell, no Wayland, no build step.

## What it is

One ordinary window — move it, resize it, minimise it, close it, screenshot it with
Cmd-Shift-4. Inside it is a **virtual monitor**, and every layer surface (bar, popouts,
notifications, session menu) is an Item positioned against that monitor rather than a
window of its own. **Resizing the window resizes the monitor**, so the bar relayouts live,
which is the quickest way to check it at a width you do not own a screen for.

The glass is the part worth getting right, so the wallpaper is drawn twice: once sharp, and
once blurred **showing only where a surface is opaque enough**. That is `layerrule blur`
gated by `layerrule ignorealpha 0.1` on Hyprland. Without it every pill reads as flat grey
and none of the colour choices in `Theme.qml` can be judged.

The palette comes from `dev/mock/colors.json`, copied to a fake `$HOME` that `Theme.qml`
finds on its own. Editing it and re-running shows a different wallpaper palette; nothing in
`common/Theme.qml` changes.

## Options

| | |
|---|---|
| `--scenario a,b,c` | what the fake services report; default `media,tray` |
| `--shot FILE` | render offscreen and write a PNG, then exit |
| `--open N` | open popout N before the shot; every run prints the list |
| `--settle MS` | how long to wait before the shot (default 1400) |
| `--width` / `--height` | starting size of the virtual monitor; dragging the window changes it |
| `--no-blur`, `--blur N` | turn the glass blur off, or change its strength |

Scenarios: `media` (two players, one playing), `tray` (three tray icons with menus),
`notifs` (three notifications arrive on a delay), `session` (session menu open), `charging`,
`lowbattery`, `wired`, `desktop` (no battery).

## What is faked

`dev/stubs/` holds a QML stand-in for every Quickshell type the shell imports — the
services are the interesting ones:

| | |
|---|---|
| `Hyprland` | 7 workspaces, 2 active, 6 urgent. `dispatch()` really moves the active workspace, so clicking and scrolling the dots drives the same animation it drives on Hyprland |
| `Mpris` | Spotify playing, Firefox paused. Position advances once a second |
| `SystemTray` | three items with working menus, including a submenu |
| `Networking` | five wifi networks, one connected, one enterprise, one open |
| `UPower`, `Pipewire`, `Notifications` | battery, sinks and sources, a notification sender |

## What it is not

Four things do not survive the trip, and all of them are visible in the code:

- **`WlrLayershell.*` is commented out** in the mirrored copy. It is a C++ attached type;
  pure QML cannot declare one. Only the layer and namespace are lost, which nothing here
  can show anyway.
- **`ClippingRectangle` clips to the bounding box**, not the rounded shape. The album art in
  `MediaCard` has square corners here and rounded ones on Hyprland.
- **No input mask, no focus grab.** `Region` masks are ignored, so a surface takes clicks
  over its whole rectangle, and clicking outside a popout does not close it — click the bar
  instead.
- **Fonts.** `"JetBrains Mono"` is rewritten to `"JetBrainsMono Nerd Font"`, which is the
  family name the same typeface registers under on macOS. The icon font matches exactly.

## How it fits together

```
preview.sh     builds everything, then runs qml
mirror.py      mirrors *.qml into .build/qs with a qmldir per directory, since `qml`
               has no idea that a directory is a module. Files needing no change are
               symlinked, so editing them shows up on the next run
mkassets.py    draws the wallpaper, album art and icons — no binaries in the repo
preview.qml    the window, the wallpaper, the blur, the screenshot
stubs/         the fake Quickshell modules
mock/          the matugen palette the preview loads
.build/        generated; gitignored
```

`PanelWindow` and `PopupWindow` are plain objects, not Windows. Each owns a
`PreviewSurface` Item that it hands to `Preview.addSurface()` to be parented into the one
scene, and the surface content is *aliased* into that Item rather than reparented
afterwards — so children have a sized visual parent from the moment they are built and
`anchors.fill: parent` never sees a null.

They cannot be `Item`s themselves: `Item.anchors` is `FINAL`, so a subclass cannot shadow
it with the layer-shell `anchors.top: true` the shell writes. That is the whole reason for
the indirection.

## When something does not load

`qml` prints the real error and the real file. Two failures come up often:

- *"Cannot assign to non-existent property"* on a grouped property — a stub declares it as
  `QtObject`. QML resolves `foo.bar:` against the **declared** type, so the property needs a
  concrete stub type. `Anchors.qml` and `PopupAnchor.qml` exist for that reason.
- *"Property 'filter' of object function values()"* — something returned a bare array where
  Quickshell returns an `ObjectModel`. A `property var` strips own properties off an array,
  so the stubs return `({ values: [...] })` instead.
