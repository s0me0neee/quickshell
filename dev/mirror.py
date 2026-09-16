#!/usr/bin/env python3
"""Mirror the shell into dev/.build/qs so the plain `qml` tool can load it.

Two things Quickshell does for free have to be done by hand here:

  * it synthesises a QML module per directory, where `qml` wants a qmldir file
  * it registers `WlrLayershell` as a C++ attached type, which pure-QML stubs cannot
    provide at all, so those lines are commented out in the mirrored copy

Files that need neither are symlinked, so editing them shows up on the next run without
anything being copied around.
"""

import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "dev" / ".build" / "qs"

# The macOS builds of these Nerd Fonts register a different family name than the Arch
# packages do. Without this every glyph falls back and nothing lines up.
FONT_SUBSTITUTIONS = {
    '"JetBrains Mono"': '"JetBrainsMono Nerd Font"',
}

ATTACHED = re.compile(r"^(\s*)(WlrLayershell\.)")

# Quickshell's ObjectModel and ScriptModel are QAbstractItemModels, so a view can take
# them directly. A pure-QML stub cannot be one, so the views are pointed at the same
# array those types wrap. Only the add/remove transitions on the network list notice.
SCRIPT_MODEL = re.compile(r"model:\s*ScriptModel\s*\{\s*\n\s*values:\s*(.+?)\s*\n\s*\}")
OBJECT_MODEL = re.compile(r"(model:\s*SystemTray\.items)(?!\.)")


def patch(text, relative):
    """Returns (patched text, list of notes) — or (None, notes) when nothing changed."""
    notes = []
    lines = text.split("\n")
    for i, line in enumerate(lines):
        if ATTACHED.match(line):
            lines[i] = ATTACHED.sub(r"\1// [preview] \2", line)
            notes.append("layershell")
    out = "\n".join(lines)

    out, count = SCRIPT_MODEL.subn(r"model: \1", out)
    notes += ["scriptmodel"] * count
    out, count = OBJECT_MODEL.subn(r"\1.values", out)
    notes += ["objectmodel"] * count

    if relative == Path("common/Appearance.qml"):
        for old, new in FONT_SUBSTITUTIONS.items():
            if old in out:
                out = out.replace(old, new)
                notes.append("font")

    return (out, notes) if notes else (None, notes)


def main():
    if OUT.exists():
        shutil.rmtree(OUT)

    sources = sorted(
        p for p in ROOT.rglob("*.qml")
        if "dev" not in p.relative_to(ROOT).parts and ".git" not in p.parts
    )

    patched = 0
    for source in sources:
        relative = source.relative_to(ROOT)
        target = OUT / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        text, notes = patch(source.read_text(), relative)
        if text is None:
            target.symlink_to(source)
        else:
            target.write_text(text)
            patched += 1

    # shell.qml is lowercase, so it is not an instantiable type and preview.qml cannot
    # put it in a scene. Copy it under a name that differs by more than case: on a
    # case-insensitive filesystem "Shell.qml" is the symlink, and writing it would go
    # straight through to the real shell.qml.
    (OUT / "PreviewShell.qml").write_text((ROOT / "shell.qml").read_text())

    directories = sorted({(OUT / p.relative_to(ROOT)).parent for p in sources})
    for directory in directories:
        module = ".".join(("qs",) + directory.relative_to(OUT).parts)
        entries = [f"module {module}"]
        for qml in sorted(directory.glob("*.qml")):
            # a qmldir type name has to be capitalised, which shell.qml is not
            if not qml.stem[0].isupper():
                continue
            singleton = "singleton " if qml.read_text().lstrip().startswith("pragma Singleton") else ""
            entries.append(f"{singleton}{qml.stem} 1.0 {qml.name}")
        (directory / "qmldir").write_text("\n".join(entries) + "\n")

    print(f"mirror: {len(sources)} files ({patched} patched), {len(directories)} modules")


if __name__ == "__main__":
    sys.exit(main())
