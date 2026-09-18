import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.common
import qs.components
import qs.services

// Opens the control center. The ring still shows the backlight and the wheel still
// dims it, the way the brightness button did; the tint is the power profile, the way
// the profile button did. Two buttons' worth of glance, one seat on the bar.
CircleButton {
    id: root

    required property QtObject bar

    property bool centerOpen: false
    readonly property bool centerLive: centerOpen || centerLinger.running

    onCenterOpenChanged: {
        if (centerOpen)
            centerLinger.stop();
        else
            centerLinger.restart();
        if (centerLoader.item)
            centerLoader.item.open = root.centerOpen;
    }

    Timer {
        id: centerLinger

        interval: Appearance.animNormal + 80
    }

    visible: Settings.data.showControlCenter
    icon: Icons.tune
    iconSize: 16
    fill: {
        if (Power.profile === PowerProfile.Performance)
            return Theme.accent;
        if (Power.profile === PowerProfile.PowerSaver)
            return Theme.accentSoft;
        return Theme.tonal;
    }
    iconColor: {
        if (Power.profile === PowerProfile.Performance)
            return Theme.primaryContainerText;
        if (Power.profile === PowerProfile.PowerSaver)
            return Theme.tertiaryContainerText;
        return Theme.secondaryContainerText;
    }
    active: root.centerOpen
    tooltip: root.centerOpen ? "" : Brightness.available ? `${Power.profileName(Power.profile)} · brightness ${Brightness.percent}%` : Power.profileName(Power.profile)
    onClicked: root.centerOpen = !root.centerOpen
    onWheel: event => Brightness.step(event.angleDelta.y > 0 ? 0.05 : -0.05)

    RingGauge {
        anchors.fill: parent
        anchors.margins: 1
        visible: Brightness.available
        value: Brightness.brightness
        color: Theme.primary
        trackColor: Qt.alpha(root.iconColor, 0.2)

        Behavior on value {
            Anim {
                duration: Appearance.animFast
            }
        }
    }

    LazyLoader {
        id: centerLoader

        active: root.centerLive

        ControlCenter {
            id: center

            target: root
            bar: root.bar
        }
    }

    Connections {
        target: centerLoader

        // Created a moment after `active` flips; open it then, animation and all
        function onItemChanged(): void {
            if (centerLoader.item)
                centerLoader.item.open = root.centerOpen;
        }
    }

    Connections {
        target: centerLoader.item

        function onOpenChanged(): void {
            if (centerLoader.item && root.centerOpen !== centerLoader.item.open)
                root.centerOpen = centerLoader.item.open;
        }
    }
}
