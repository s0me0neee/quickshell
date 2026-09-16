import QtQuick

// No global pointer grab in the preview; popouts close through their own bar click
QtObject {
    property bool active: false
    property var windows: []

    signal cleared
}
