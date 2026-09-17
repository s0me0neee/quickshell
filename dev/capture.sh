#!/usr/bin/env bash
# Record the screen while you reproduce a visual glitch, then split it into frames.
#
# Screenshots cannot see compositor artifacts. grim (and anything else using
# wlr-screencopy for a single shot) asks Hyprland to re-render the scene into a fresh
# buffer, which draws exactly the correct picture and erases the thing you are chasing.
# A continuous recording captures composited output as it actually went out.
#
#   dev/capture.sh trail 8     # record 8 seconds, then extract frames
#
# Reproduce the glitch while it runs. Frames land in /tmp/qs-frames/<label>/ as
# f001.png, f002.png ... at 60fps, so frame N happened at N/60 seconds.
# Then measure with dev/framediff.py, or just look at the frames either side.
set -euo pipefail

LABEL=${1:-glitch}
SECONDS_TO_RECORD=${2:-8}
OUT=/tmp/qs-frames/$LABEL
CLIP=$OUT/clip.mkv

command -v wf-recorder >/dev/null || {
    echo "wf-recorder is not installed: sudo pacman -S wf-recorder" >&2
    exit 1
}

rm -rf "$OUT"
mkdir -p "$OUT"

echo "recording ${SECONDS_TO_RECORD}s — reproduce it now"
# -f is not optional: without it wf-recorder drops recording.mkv in the working
# directory, which here is the repo
wf-recorder -r 60 -f "$CLIP" >/dev/null 2>&1 &
REC=$!
sleep "$SECONDS_TO_RECORD"
kill -INT $REC 2>/dev/null || true
wait $REC 2>/dev/null || true

ffmpeg -hide_banner -loglevel error -i "$CLIP" -fps_mode passthrough "$OUT/f%03d.png"
echo "$(ls -1 "$OUT"/f*.png | wc -l) frames in $OUT"
echo "next: dev/framediff.py $LABEL <x> <y> <w> <h>"
