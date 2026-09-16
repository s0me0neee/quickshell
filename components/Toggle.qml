import QtQuick
import qs.common

// On/off switch. Emits toggled(); `checked` is only set from outside.
MouseArea {
    id: root

    property bool checked: false

    signal toggled

    implicitWidth: 40
    implicitHeight: 22
    cursorShape: Qt.PointingHandCursor
    hoverEnabled: true
    onClicked: toggled()

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? Theme.primary : Qt.alpha(Theme.surfaceText, 0.15)
        border.width: root.checked ? 0 : 1
        border.color: Qt.alpha(Theme.outline, 0.6)

        Behavior on color {
            CAnim {
                duration: Appearance.animNormal
            }
        }

        Rectangle {
            readonly property real inset: root.checked ? 3 : 5

            x: root.checked ? parent.width - width - inset : inset
            anchors.verticalCenter: parent.verticalCenter
            width: parent.height - inset * 2
            height: width
            radius: width / 2
            color: root.checked ? Theme.primaryText : Theme.outline
            scale: root.pressed ? 0.85 : 1

            Behavior on x {
                Anim {
                    easing.bezierCurve: Appearance.curveEmphasized
                }
            }

            Behavior on width {
                Anim {}
            }

            Behavior on color {
                CAnim {
                    duration: Appearance.animNormal
                }
            }

            Behavior on scale {
                Anim {
                    duration: Appearance.animFast
                }
            }
        }
    }
}
