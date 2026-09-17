#!/usr/bin/env python3
"""Click the mouse at its current position via /dev/uinput.

Hyprland has no click dispatcher and this box has no ydotool; the user is in
the `input` group, so a virtual pointer can be created directly. Use hyprctl
`dispatch movecursor X Y` to aim first.

Usage: click.py [left|right|middle]
"""
import fcntl
import struct
import sys
import time

UI_DEV_CREATE = 0x5501
UI_DEV_DESTROY = 0x5502
UI_DEV_SETUP = 0x405C5503
UI_SET_EVBIT = 0x40045564
UI_SET_KEYBIT = 0x40045565
UI_SET_RELBIT = 0x40045566
EV_SYN, EV_KEY, EV_REL = 0, 1, 2
REL_X, REL_Y = 0, 1
BUTTONS = {"left": 0x110, "right": 0x111, "middle": 0x112}

btn = BUTTONS[sys.argv[1] if len(sys.argv) > 1 else "left"]

fd = open("/dev/uinput", "wb", buffering=0)
fcntl.ioctl(fd, UI_SET_EVBIT, EV_KEY)
fcntl.ioctl(fd, UI_SET_EVBIT, EV_REL)
fcntl.ioctl(fd, UI_SET_KEYBIT, btn)
fcntl.ioctl(fd, UI_SET_RELBIT, REL_X)
fcntl.ioctl(fd, UI_SET_RELBIT, REL_Y)

# struct uinput_setup: input_id (4x u16) + name[80] + ff_effects_max (u32)
fcntl.ioctl(fd, UI_DEV_SETUP, struct.pack("4H80sI", 0, 0, 0, 0, b"qs-click", 0))
fcntl.ioctl(fd, UI_DEV_CREATE)

# udev and libinput need a moment to enumerate the device; a click sent before
# Hyprland has it attached lands nowhere
import subprocess

deadline = time.time() + 3.0
while time.time() < deadline:
    out = subprocess.run(
        ["hyprctl", "devices"], capture_output=True, text=True
    ).stdout
    if "qs-click" in out:
        break
    time.sleep(0.15)


def emit(type_, code, value):
    fd.write(struct.pack("LLHHi", 0, 0, type_, code, value))


emit(EV_KEY, btn, 1)
emit(EV_SYN, 0, 0)
time.sleep(0.06)
emit(EV_KEY, btn, 0)
emit(EV_SYN, 0, 0)
time.sleep(0.06)
fcntl.ioctl(fd, UI_DEV_DESTROY)
fd.close()
