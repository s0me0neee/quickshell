import QtQuick
import Quickshell

QtObject {
    property string id: ""
    property string title: ""
    property string tooltipTitle: ""
    // A string, not a url: Tray.qml parses the "name?path=/dir" form out of it
    property string icon: ""
    property bool onlyMenu: false
    property bool hasMenu: true
    property QsMenuHandle menu: null

    function activate(): void {
        console.log("[preview] tray activate:", id);
    }

    function secondaryActivate(): void {
        console.log("[preview] tray secondaryActivate:", id);
    }

    function scroll(delta: int, horizontal: bool): void {}
}
