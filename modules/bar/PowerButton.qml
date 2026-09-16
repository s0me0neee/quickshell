import QtQuick
import qs.common
import qs.components
import qs.services

CircleButton {
    icon: Icons.power
    iconSize: 18
    fill: Theme.tonal
    iconColor: Theme.secondaryContainerText
    tooltip: "Power menu"
    onClicked: Session.openMenu()
}
