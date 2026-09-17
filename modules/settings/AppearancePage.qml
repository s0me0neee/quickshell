import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// Every control here reaches a token in Appearance.qml or Theme.qml, so the whole shell
// redraws as you move it — including this window.
ColumnLayout {
    id: root

    spacing: Appearance.spacingLarge

    Section {
        title: "Glass"

        SettingRow {
            label: "Opacity"
            description: "How much wallpaper comes through. Hyprland blurs what is behind."

            Stepper {
                value: Math.round(Settings.data.glassOpacity * 100)
                from: 10
                to: 95
                step: 5
                format: value => `${value}%`
                onMoved: value => {
                    Settings.data.glassOpacity = value / 100;
                    Settings.save();
                }
            }
        }

        SettingRow {
            label: "Corner radius"
            description: "Panels and popouts. Rows inside them follow along."

            Stepper {
                value: Settings.data.radiusPanel
                from: 0
                to: 32
                onMoved: value => {
                    Settings.data.radiusPanel = value;
                    Settings.save();
                }
            }
        }
    }

    Section {
        title: "Text"

        SettingRow {
            label: "Font size"
            description: "Small text is always two below it."

            Stepper {
                value: Settings.data.fontSize
                from: 10
                to: 20
                onMoved: value => {
                    Settings.data.fontSize = value;
                    Settings.save();
                }
            }
        }

        SettingRow {
            label: `${Appearance.fontFamily} · ${Appearance.iconFamily}`
            description: "Set in common/Appearance.qml. Swapping one means checking the glyphs, not clicking a button."
        }
    }

    Section {
        title: "Colour"

        SettingRow {
            label: "Palette"
            description: "From the wallpaper, via matugen, reloaded live. No light/dark switch: matugen writes one palette for the whole desktop, so flipping it would recolour Hyprland too."

            StyledText {
                text: Theme.wallpaper ? "From wallpaper" : "Fallback"
                color: Theme.primary
                font.pixelSize: Appearance.fontSizeSmall
                font.weight: Font.DemiBold
            }
        }
    }
}
