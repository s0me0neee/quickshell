import QtQuick
import Quickshell.Services.UPower
import qs.common
import qs.components
import qs.services

// Click cycles power saver -> balanced -> performance.
CircleButton {
    id: root

    icon: {
        if (Power.profile === PowerProfile.Performance)
            return Icons.profilePerformance;
        if (Power.profile === PowerProfile.PowerSaver)
            return Icons.profilePowerSaver;
        return Icons.profileBalanced;
    }
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
    tooltip: {
        if (Power.profile === PowerProfile.Performance)
            return "Performance";
        if (Power.profile === PowerProfile.PowerSaver)
            return "Power saver";
        return "Balanced";
    }
    onClicked: Power.cycleProfile()
}
