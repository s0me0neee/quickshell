import QtQuick

// Reads the file once through XMLHttpRequest, which handles file:// URLs. Theme.qml
// only needs `loaded` plus `text()`; nothing here watches for changes.
QtObject {
    id: root

    property string path: ""
    property bool watchChanges: false
    property bool blockLoading: false
    property string contents: ""

    signal loaded
    signal loadFailed
    signal fileChanged

    function text(): string {
        return contents;
    }

    function reload(): void {
        if (path === "")
            return;
        const request = new XMLHttpRequest();
        request.onreadystatechange = function () {
            if (request.readyState !== XMLHttpRequest.DONE)
                return;
            // A file:// read reports status 0 on success
            if (request.status === 0 || request.status === 200) {
                root.contents = request.responseText;
                root.loaded();
            } else {
                root.loadFailed();
            }
        };
        request.open("GET", path.startsWith("/") ? `file://${path}` : path);
        request.send();
    }

    onPathChanged: reload()
    Component.onCompleted: reload()
}
