import QtQuick

QtObject {
    property bool isLaptopBattery: true
    property real percentage: 0.62
    property int state: UPowerDeviceState.Discharging
    property real timeToFull: 0
    property real timeToEmpty: 8100
    property bool ready: true
}
