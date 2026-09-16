import QtQuick

QtObject {
    id: root

    enum Precision {
        Seconds,
        Minutes,
        Hours
    }

    property int precision: SystemClock.Seconds
    property bool enabled: true

    property date date: new Date()
    readonly property int hours: date.getHours()
    readonly property int minutes: date.getMinutes()
    readonly property int seconds: date.getSeconds()

    readonly property Timer tick: Timer {
        running: root.enabled
        repeat: true
        interval: root.precision === SystemClock.Seconds ? 1000 : 5000
        onTriggered: root.date = new Date()
    }
}
