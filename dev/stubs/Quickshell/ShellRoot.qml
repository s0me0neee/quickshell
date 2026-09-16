import QtQuick

// An Item rather than a bare object, so preview.qml can hang the whole shell off its
// scene and the windows inside still find a QML engine to live in.
Item {
    visible: false
}
