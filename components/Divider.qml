import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    Layout.fillWidth: true
    Layout.topMargin: Appearance.spacingSmall
    Layout.bottomMargin: Appearance.spacingSmall
    implicitHeight: 1
    color: Qt.alpha(Theme.outlineVariant, 0.6)
}
