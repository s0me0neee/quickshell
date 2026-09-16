#!/usr/bin/env python3
"""Generate the images the preview needs: a wallpaper to show through the glass, album
art, and tray/notification icons. Written by hand so the repo carries no binaries."""

import json
import math
import struct
import sys
import zlib
from pathlib import Path


def write_png(path, width, height, pixels):
    """pixels: flat list of (r, g, b, a) tuples, row-major."""
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        for x in range(width):
            raw.extend(pixels[y * width + x])

    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")
    path.write_bytes(png)


def hex_rgb(value):
    value = value.lstrip("#")
    return tuple(int(value[i:i + 2], 16) for i in (0, 2, 4))


def wallpaper(path, palette, width=640, height=400):
    """Soft blobs over a diagonal gradient. Drawn small and stretched by Qt: the glass
    only ever shows a blurred version of it, so resolution buys nothing."""
    dark = hex_rgb(palette["surface"])
    blobs = [
        (0.18, 0.25, 0.42, hex_rgb(palette["primary_container"])),
        (0.72, 0.18, 0.38, hex_rgb(palette["tertiary_container"])),
        (0.55, 0.78, 0.45, hex_rgb(palette["secondary_container"])),
        (0.92, 0.62, 0.30, hex_rgb(palette["primary"])),
        (0.08, 0.88, 0.28, hex_rgb(palette["tertiary"])),
    ]
    pixels = []
    for y in range(height):
        v = y / height
        for x in range(width):
            u = x / width
            # base gradient, brighter toward the top left
            fade = 1.0 - 0.45 * (u * 0.6 + v * 0.8)
            r, g, b = (c * fade for c in dark)
            for bx, by, radius, colour in blobs:
                dx = (u - bx) * (width / height)
                dy = v - by
                d = math.sqrt(dx * dx + dy * dy) / radius
                if d >= 1.0:
                    continue
                # smoothstep falloff, so no blob shows an edge
                w = (1.0 - d * d) ** 2 * 0.55
                r += colour[0] * w
                g += colour[1] * w
                b += colour[2] * w
            pixels.append((min(255, int(r)), min(255, int(g)), min(255, int(b)), 255))
    write_png(path, width, height, pixels)


def artwork(path, palette, size=320):
    """Concentric rings: recognisably album-art shaped, and its own resolution test."""
    a = hex_rgb(palette["primary"])
    b = hex_rgb(palette["tertiary"])
    bg = hex_rgb(palette["primary_container"])
    pixels = []
    for y in range(size):
        for x in range(size):
            dx = x / size - 0.5
            dy = y / size - 0.5
            d = math.sqrt(dx * dx + dy * dy)
            ring = (math.sin(d * 46) + 1) / 2
            t = min(1.0, d * 2)
            colour = [a[i] * (1 - t) + b[i] * t for i in range(3)]
            mix = 0.35 + 0.65 * ring
            pixels.append(tuple(int(bg[i] * (1 - mix) + colour[i] * mix) for i in range(3)) + (255,))
    write_png(path, size, size, pixels)


def icon(path, colour, kind, size=64):
    """Thin-stroked marks. Fine detail on purpose: an icon drawn at the wrong pixel size
    shows it here before it shows it on the bar."""
    r, g, b = colour
    pixels = []
    for y in range(size):
        for x in range(size):
            u = (x + 0.5) / size - 0.5
            v = (y + 0.5) / size - 0.5
            d = math.sqrt(u * u + v * v)
            on = False
            if kind == "rings":
                on = any(abs(d - k) < 0.042 for k in (0.14, 0.28, 0.42))
            elif kind == "square":
                edge = max(abs(u), abs(v))
                on = any(abs(edge - k) < 0.042 for k in (0.16, 0.31, 0.46))
            elif kind == "cross":
                on = (abs(u) < 0.05 or abs(v) < 0.05) and d < 0.46
                on = on or abs(d - 0.46) < 0.042
            alpha = 255 if on else 0
            pixels.append((r, g, b, alpha))
    write_png(path, size, size, pixels)


def main():
    out = Path(sys.argv[1])
    palette = json.loads(Path(sys.argv[2]).read_text())
    out.mkdir(parents=True, exist_ok=True)

    wallpaper(out / "wallpaper.png", palette)
    artwork(out / "artwork.png", palette)

    marks = {
        "tray-network": (hex_rgb(palette["on_surface"]), "rings"),
        "tray-bluetooth": (hex_rgb(palette["primary"]), "square"),
        "tray-input": (hex_rgb(palette["tertiary"]), "cross"),
        "notif-chat": (hex_rgb(palette["primary"]), "rings"),
        "notif-update": (hex_rgb(palette["tertiary"]), "square"),
        "notif-battery": (hex_rgb(palette["error"]), "cross"),
    }
    for name, (colour, kind) in marks.items():
        icon(out / f"{name}.png", colour, kind)

    print(f"assets: {len(marks) + 2} images in {out}")


if __name__ == "__main__":
    main()
