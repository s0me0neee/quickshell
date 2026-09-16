import QtQuick

// One copy of the delegate per model entry, each with `modelData` set. Built by hand
// rather than with an Instantiator because the delegates here are windows, not items.
QtObject {
    id: root

    property var model: []
    default property Component delegate

    property var instances: []

    function rebuild(): void {
        for (const old of instances)
            old.destroy();
        const made = [];
        for (const entry of model)
            made.push(delegate.createObject(root, {
                        modelData: entry
                    }));
        instances = made;
    }

    onModelChanged: rebuild()
    Component.onCompleted: rebuild()
}
