import QtQuick

QsMenuHandle {
    property string text: ""
    property string icon: ""
    property bool enabled: true
    property bool isSeparator: false
    property bool hasChildren: entries.length > 0
    property int buttonType: QsMenuButtonType.None
    property int checkState: Qt.Unchecked

    signal triggered
}
