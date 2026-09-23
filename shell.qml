// Only load Mesa's EGL (Intel iGPU). Without this, glvnd also loads the NVIDIA EGL
// libraries (~95 MB) just to probe them, even though the shell never renders there.
//@ pragma Env __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json

import QtQuick
import Quickshell
import qs.modules.bar
import qs.modules.clipboard
import qs.modules.launcher
import qs.modules.notifications
import qs.modules.osd
import qs.modules.polkit
import qs.modules.session
import qs.modules.settings
import qs.services

ShellRoot {
    Bar {}

    // Notification surfaces are not needed until a notification is actually popping.
    // Keeping the layer unmapped while idle avoids an extra window and its card tree.
    LazyLoader {
        active: Notifs.popupLive

        Popups {}
    }

    LazyLoader {
        active: Clipboard.live

        ClipboardWindow {}
    }

    // Built when you open it, dropped once it has faded out
    LazyLoader {
        active: Launcher.live

        LauncherWindow {}
    }

    // Only while a fullscreen window is hiding the bar — the island shows the OSD the
    // rest of the time, so this surface doesn't exist on an ordinary volume change.
    LazyLoader {
        active: Osd.overlayLive

        OsdWindow {}
    }

    // Built on first use, and kept only until it has faded back out
    LazyLoader {
        active: Session.menuLive

        SessionMenu {}
    }

    // The agent itself lives in the Polkit singleton; only the prompt waits for a request
    LazyLoader {
        active: Polkit.live

        PolkitDialog {}
    }

    LazyLoader {
        active: Settings.menuLive

        SettingsWindow {}
    }
}
