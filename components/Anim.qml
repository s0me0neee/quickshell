import QtQuick
import qs.common

NumberAnimation {
    duration: Appearance.animNormal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.curveStandard
}
