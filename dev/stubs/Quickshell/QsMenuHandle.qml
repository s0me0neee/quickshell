import QtQuick

// A menu, or a submenu. QsMenuEntry is one of these too, which is what lets TrayMenu
// push an entry onto its path and reopen it as the current menu.
QtObject {
    default property list<QsMenuHandle> entries
}
