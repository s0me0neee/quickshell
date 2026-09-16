import QtQuick

QtObject {
    id: root

    property string summary: ""
    property string body: ""
    property string appName: ""
    property string appIcon: ""
    property string image: ""
    property int urgency: NotificationUrgency.Normal
    property real expireTimeout: -1
    // Plain objects: NotifEntry only reads identifier/text and calls invoke()
    property var actions: []
    property bool tracked: false

    signal closed

    function dismiss(): void {
        root.closed();
    }
}
