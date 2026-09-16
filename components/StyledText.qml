import QtQuick
import qs.common

Text {
    color: Theme.surfaceText
    font.family: Appearance.fontFamily
    font.pixelSize: Appearance.fontSize
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight

    Behavior on color {
        CAnim {}
    }
}
