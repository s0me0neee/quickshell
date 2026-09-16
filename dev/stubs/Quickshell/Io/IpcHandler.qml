import QtQuick

// There is no `qs ipc` socket behind the preview; the handlers just sit there
QtObject {
    property string target: ""
    property bool enabled: true
}
