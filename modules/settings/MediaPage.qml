import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

ColumnLayout {
    id: root

    spacing: Appearance.spacingLarge

    Section {
        title: "Visualiser"

        SettingRow {
            label: "Show the spectrum"
            description: "Bars in the media card, from cava. It is the only thing in the shell that redraws continuously — about 7% of one core while the card is open, and nothing when it is shut."

            Toggle {
                checked: Settings.data.visualiser
                onToggled: {
                    Settings.data.visualiser = !Settings.data.visualiser;
                    Settings.save();
                }
            }
        }

        SettingRow {
            label: "Bars"
            visible: Settings.data.visualiser

            Stepper {
                value: Settings.data.visualiserBars
                from: 8
                to: 48
                step: 2
                onMoved: value => {
                    Settings.data.visualiserBars = value;
                    Settings.save();
                }
            }
        }

        SettingRow {
            label: "Frame rate"
            description: "The cost is roughly proportional to this. Below about 20 the bars start to look like they are stepping."
            visible: Settings.data.visualiser

            Stepper {
                value: Settings.data.visualiserFramerate
                from: 10
                to: 60
                step: 5
                format: value => `${value}fps`
                onMoved: value => {
                    Settings.data.visualiserFramerate = value;
                    Settings.save();
                }
            }
        }

        SettingRow {
            label: "cava"
            visible: Settings.data.visualiser
            description: Cava.running ? "Running now." : "Not running — it starts when the card is open and something is playing."
        }
    }

    Section {
        title: "Players"

        SettingRow {
            label: "Now playing"
            description: Media.sorted.length === 0 ? "Nothing is claiming MPRIS." : "The island follows whichever player is actually playing; click a chip on the card to pin a different one."

            StyledText {
                text: Media.active?.identity ?? "None"
                color: Theme.primary
                font.pixelSize: Appearance.fontSizeSmall
                font.weight: Font.DemiBold
            }
        }
    }
}
