pragma Singleton

import QtQuick

QtObject {
    property int profile: PowerProfile.Balanced
    readonly property bool hasPerformanceProfile: true
}
