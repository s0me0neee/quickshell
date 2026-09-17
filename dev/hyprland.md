# Seeing what Hyprland actually draws

Notes from chasing a rendering bug that took four attempts, because the tools lied.
[dev/README.md](README.md) covers the opposite problem — running the shell with no
Wayland at all.

## Screenshots cannot see compositor artifacts

`grim` asks the compositor to **re-render the scene** into a fresh buffer. It draws the
correct picture every time. So does any other single-shot screencopy tool, and so does
Quickshell's own capture.

This means a whole class of bug is invisible to a screenshot: anything where the wrong
pixels are on screen because something *failed to be repainted*. Chasing one of those
with `grim`, you will take clean shot after clean shot while the person next to you is
looking straight at the glitch.

**Use a recording instead.** `wf-recorder` captures composited output frame by frame and
does show them:

```sh
dev/capture.sh trail 8                  # record 8s, split into frames
dev/framediff.py trail 976 330 344 150  # which frames differ, and by how much
```

Keep the background still while recording — a terminal printing output under the panel
changes those pixels for real and reads exactly like an artifact. An artifact fades over
a few frames right after the event; background churn is steady and scattered. Look at the
frames it flags before believing the number.

`framediff.py` compares every frame against the last one in the clip. Record a second
past the end of the glitch and the last frame is what the screen *should* have shown
throughout, so anything it flags is the artifact. It prints a timestamp per frame, which
tells you how long the artifact lasted and whether it faded (something is being drawn
over) or stopped dead (something was simply still there).

If you ever need the literal scanout buffer rather than the composited scene,
`ffmpeg -f kmsgrab` reads it, but it needs root and on Intel the framebuffer is tiled, so
it cannot be copied to the CPU — map it to the GPU encoder instead:

```sh
sudo ffmpeg -device /dev/dri/card1 -f kmsgrab -framerate 60 -t 10 -i - \
  -vf 'hwmap=derive_device=vaapi,scale_vaapi=format=nv12' -c:v h264_vaapi -qp 18 out.mp4
```

(`card1` is the Intel iGPU driving eDP-1; `card0` is the NVIDIA card and drives nothing.)

## A layer surface must never shrink while it is visible

**The bug.** Hyprland leaves a stale translucent rectangle over the area a layer surface
stops covering, when that surface gets *smaller*. Growing is fine. It lasts about a
quarter of a second and fades out, so it reads as the panel dragging a ghost of itself.

**What it is not.** All measured, all still trailed: blur on the layer (`blur off`), blur
caching (`new_optimizations false`), the `layers` animation, the `fade` tree, the
`windows` tree. Only `animations:enabled 0` hid it, which is not a fix.

**The fix**, in [components/Popout.qml](../components/Popout.qml): the surface only ever
grows while the popout is on screen. It expands to fit before the panel does, and gives
the height back in `onVisibleChanged` — once it is unmapped, where no one can see it
shrink. A `mask` keeps the surface, which is now sometimes taller than it looks, from
eating clicks meant for windows underneath.

So: **animate anything you like inside a layer surface. Just don't make the surface
smaller while someone is looking at it.**

## Three wrong turns, for the pattern

Each of these looked like the fix for the one before it:

| Attempt | Surface resizes | Transparent band inside it | Result |
| --- | --- | --- | --- |
| Ease the surface height | per frame | never | jitter — content lags the geometry |
| Hold the surface, ease the panel inside | 2, one a shrink | for the animation | trails |
| Glue the surface to the panel | per frame | never | jitter again |
| Snap the height | 1, a shrink | never | trails, on decrease only |

The lesson is not about any of those mechanisms. It is that **three rounds were spent
guessing because there was no instrument**, and the moment one existed the answer took
two runs. If a visual bug cannot be reproduced in a screenshot, stop changing code and
go get a recording first.
