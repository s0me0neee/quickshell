#!/usr/bin/env bash
# Run the bar on a machine that is not the Linux box it was written for.
#
#   ./dev/preview.sh                          open it in a window
#   ./dev/preview.sh --shot bar.png           render it offscreen to a file
#   ./dev/preview.sh --scenario notifs        pick what the fake services report
#
# Anything else is passed through to preview.qml; see dev/README.md.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
build="$here/.build"
assets="$build/assets"
home="$build/home"

command -v qml >/dev/null || {
	echo "qml not found — install Qt 6 (brew install qt)" >&2
	exit 1
}

python3 "$here/mirror.py"
python3 "$here/mkassets.py" "$assets" "$here/mock/colors.json"

# Theme.qml builds its path out of $HOME, so the palette goes where it expects to find it
mkdir -p "$home/.local/state/quickshell"
cp "$here/mock/colors.json" "$home/.local/state/quickshell/colors.json"

# The FileView stub reads that palette over XHR, which refuses file:// without this
export QML_XHR_ALLOW_FILE_READ=1

args=(
	--home "$home"
	--wallpaper "file://$assets/wallpaper.png"
	--artwork "file://$assets/artwork.png"
	--icons "file://$assets"
)

# A screenshot has nothing to display on, and wants a deterministic frame
for arg in "$@"; do
	if [[ $arg == --shot ]]; then
		export QT_QPA_PLATFORM=offscreen
	fi
done

exec qml -I "$here/stubs" -I "$build" "$here/preview.qml" -- "${args[@]}" "$@"
