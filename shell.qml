// Only load Mesa's EGL (Intel iGPU). Without this, glvnd also loads the NVIDIA EGL
// libraries (~95 MB) just to probe them, even though the shell never renders there.
//@ pragma Env __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json

import QtQuick
import Quickshell
import qs.modules.bar
import qs.modules.notifications
import qs.modules.session
import qs.services

ShellRoot {
    Bar {}

    Popups {}

    // Built on first use, and kept only until it has faded back out
    LazyLoader {
        active: Session.menuOpen || (item?.progress ?? 0) > 0.01

        SessionMenu {}
    }
}
