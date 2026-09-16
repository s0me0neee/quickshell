import QtQuick
import QtQuick.Layouts
import qs.common

// Content that slides open sideways when `shown` is true. It brings its own leading
// gap, so put it in a row with no spacing before it (layouts can't cancel spacing).
Item {
    id: root

    property bool shown: false
    property real gap: Appearance.spacing
    default property alias content: holder.data

    implicitWidth: shown ? holder.implicitWidth + gap : 0
    implicitHeight: holder.implicitHeight
    clip: true
    opacity: shown ? 1 : 0

    Behavior on implicitWidth {
        Anim {
            duration: Appearance.animNormal
            easing.bezierCurve: Appearance.curveEmphasized
        }
    }

    Behavior on opacity {
        Anim {
            duration: Appearance.animFast
        }
    }

    RowLayout {
        id: holder

        x: root.gap
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing
    }
}
