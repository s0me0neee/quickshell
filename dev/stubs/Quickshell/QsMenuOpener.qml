import QtQuick

QtObject {
    property QsMenuHandle menu: null
    readonly property var children: menu?.entries ?? []
}
