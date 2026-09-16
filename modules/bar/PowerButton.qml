import QtQuick
import qs.common
import qs.components
import qs.services

CircleButton {
    icon: Icons.power
    iconSize: 20
    fill: Theme.tonal
    iconColor: Theme.secondaryContainerText
    tooltip: "Power menu"
    onClicked: Session.openMenu()
}
