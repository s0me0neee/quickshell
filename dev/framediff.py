#!/usr/bin/env python3
"""Say which frames of a capture differ from the settled picture, inside one region.

A visual artifact is whatever is on screen that should not be. Point this at the
region it appears in and it compares every frame against the last one — which, if
the capture ran a second past the end of the glitch, is what the screen *should*
have looked like the whole time.

    dev/capture.sh trail 8
    dev/framediff.py trail 976 330 344 150

Prints one line per frame that differs, so you can see how long the artifact lasted
and whether it faded or snapped. Frame N is at N/60 seconds into the clip.

The region is x y w h in screen pixels. `hyprctl layers` gives you a surface's
geometry; for something left behind by a surface that shrank, the region is the part
it used to cover and no longer does.

Keep whatever is *behind* the region still while recording. A terminal printing
output under the panel changes those pixels legitimately and shows up here exactly
like an artifact would. Two things tell them apart: an artifact fades over a few
frames and sits right after the event, while background churn is steady and scattered.
Look at the flagged frames before believing the number.
"""

import glob
import os
import sys

from PIL import Image, ImageChops, ImageStat


def main() -> int:
    if len(sys.argv) < 6:
        print(__doc__)
        return 2

    label = sys.argv[1]
    x, y, w, h = (int(v) for v in sys.argv[2:6])
    threshold = float(sys.argv[6]) if len(sys.argv) > 6 else 3.0

    folder = label if os.path.isdir(label) else f"/tmp/qs-frames/{label}"
    frames = sorted(glob.glob(f"{folder}/f*.png"))
    if not frames:
        print(f"no frames in {folder} — run dev/capture.sh {label} first")
        return 1

    box = (x, y, x + w, y + h)
    settled = Image.open(frames[-1]).convert("RGB").crop(box)

    print(f"{len(frames)} frames, region {w}x{h} at {x},{y}, threshold {threshold}")
    flagged = []
    for path in frames:
        current = Image.open(path).convert("RGB").crop(box)
        mean = sum(ImageStat.Stat(ImageChops.difference(current, settled)).mean) / 3
        if mean > threshold:
            flagged.append((os.path.basename(path), mean))

    if not flagged:
        print("clean: nothing in that region differs from the settled frame")
        return 0

    for name, mean in flagged:
        frame_no = int("".join(c for c in name if c.isdigit()))
        print(f"  {name}  t={frame_no / 60:5.2f}s  differs by {mean:6.2f}")

    # A run that fades out is an artifact being drawn over; one that stops dead is
    # usually just the thing you were interacting with still being there
    print(f"\n{len(flagged)} frames differ, {flagged[0][1]:.1f} at worst")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
