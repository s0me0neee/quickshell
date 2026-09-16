pragma Singleton

import QtQuick
import Quickshell

// Only one bar popout is open at a time: opening one closes the others.
Singleton {
    property QtObject current: null
}
