import QtQuick
import qs.common

ColorAnimation {
    duration: Appearance.animSlow
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Appearance.curveStandard
}
