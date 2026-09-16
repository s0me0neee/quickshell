import QtQuick

QtObject {
    id: root

    property bool active: false
    default property Component delegate
    property var item: null

    onActiveChanged: {
        if (active && !item) {
            item = delegate.createObject(root);
        } else if (!active && item) {
            item.destroy();
            item = null;
        }
    }
}
