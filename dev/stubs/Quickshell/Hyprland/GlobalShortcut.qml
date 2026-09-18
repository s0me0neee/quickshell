import QtQuick

// No hyprland_global_shortcuts_v1 in the preview, so nothing fires. The type still has to
// exist for the shell to load.
QtObject {
    property string appid: "quickshell"
    property string name: ""
    property string description: ""
    property string triggerDescription: ""

    signal pressed
    signal released
}
