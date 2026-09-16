# quickshell

One Quickshell shell for Hyprland: a floating glass bar coloured from the wallpaper,
with popouts, a media island and a session menu. Design notes and the roadmap are in
[PLAN.md](PLAN.md).

Everything the shell needs is in this repo except the packages below, so it moves to
another machine with a clone and two lines of config.

## Dependencies

| Package | Why |
|---|---|
| `quickshell` (0.3.1+) | the shell itself |
| `matugen` | generates the palette from the wallpaper |
| `ttf-jetbrains-mono` | UI font (`Appearance.fontFamily`) |
| `ttf-firacode-nerd` | icon glyphs (`Appearance.iconFamily`) |
| `swaync` | notifications, until Phase 2 replaces it |
| `wlogout` | *no longer needed* — the session menu replaces it |
| `networkmanager`, `pipewire`, `power-profiles-daemon`, `upower` | what the status pills read |

```sh
sudo pacman -S quickshell matugen ttf-jetbrains-mono ttf-firacode-nerd
```

## Install

```sh
git clone <this repo> ~/.config/quickshell
```

**1. Hyprland** — source the snippet from your Hyprland config:

```
source = ~/.config/quickshell/hypr/quickshell.conf
```

It carries the blur rules for the shell's layer surfaces, the autostart line and the
restart bind. See [hypr/quickshell.conf](hypr/quickshell.conf).

**2. matugen** — add the template to `~/.config/matugen/config.toml`:

```toml
[templates.quickshell]
input_path = '~/.config/quickshell/matugen/quickshell-colors.json'
output_path = '~/.local/state/quickshell/colors.json'
```

The palette is generated state, not config, so it lives in `~/.local/state` and never
shows up as a change in this repo. `Theme.qml` watches that file and recolours the
shell live, with no restart. Until matugen has run once, the shell falls back to the
palette hardcoded in `common/Theme.qml`.

## Running

| | |
|---|---|
| Run while developing (live reload, logs in the terminal) | `qs -p ~/.config/quickshell` |
| Logs of the running shell | `qs log -f` |
| Restart | `qs kill; qs -d -n` |
| Memory / CPU | `ps -o rss,pcpu -C quickshell` |

Editing any file reloads the shell immediately — there is no build step.

On a machine without Hyprland — a Mac, or anything not Wayland — `./dev/preview.sh` runs
the same files under the plain `qml` tool against fake services, in a window or straight to
a PNG. See [dev/README.md](dev/README.md).

## Layout

```
shell.qml      entry point
common/        Theme (matugen colours), Appearance (sizes, motion), Icons, PopoutState
components/    reusable widgets: Pill, CircleButton, Popout, Tooltip, RingGauge, ...
services/      singletons that talk to the system: Audio, Power, Network, Media, Session, ...
modules/bar/   the bar and everything in it
modules/session/  the session menu
matugen/       the colour template this shell reads
hypr/          the Hyprland snippet
dev/           preview harness: runs the shell off-Linux against fake services
```

Rules that keep it fast and consistent are in [PLAN.md](PLAN.md): only `services/` start
processes, nothing animates forever, closed panels aren't loaded, and Hyprland does the
blur rather than QML.

## Fonts

The shell uses system fonts rather than bundling any, so a clone is small and the text
matches the rest of the desktop. If you would rather it be fully self-contained, drop
the TTFs in `assets/fonts/` and point `common/Appearance.qml` at them through a
`FontLoader`.
