import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// Nothing is converted on the way in: NOAA reports °F and mph, /proc counts kibibytes,
// and that is what gets cached. The conversion happens on the way to the screen, so
// changing a unit here never means re-fetching anything.
ColumnLayout {
    id: root

    spacing: Appearance.spacingLarge

    Section {
        title: "Weather"

        SettingRow {
            label: "Temperature"

            Choice {
                options: ["°F", "°C"]
                current: Settings.data.celsius ? 1 : 0
                onPicked: index => {
                    Settings.data.celsius = index === 1;
                    Settings.save();
                }
            }
        }

        SettingRow {
            label: "Wind speed"

            Choice {
                options: ["mph", "km/h"]
                current: Settings.data.metricWind ? 1 : 0
                onPicked: index => {
                    Settings.data.metricWind = index === 1;
                    Settings.save();
                }
            }
        }

        SettingRow {
            label: "Right now"
            description: Weather.available ? `${Weather.city}, from NOAA` : "No forecast yet."

            StyledText {
                visible: Weather.available
                text: `${Math.round(Settings.temperature(Weather.now?.temperature ?? 0))}°${Settings.temperatureUnit}`
                color: Theme.primary
                font.weight: Font.DemiBold
            }
        }
    }

    Section {
        title: "System"

        SettingRow {
            label: "Memory"
            description: "GiB is what the kernel means; GB is what the sticker on the machine said."

            Choice {
                options: ["GiB", "GB"]
                current: Settings.data.decimalBytes ? 1 : 0
                onPicked: index => {
                    Settings.data.decimalBytes = index === 1;
                    Settings.save();
                }
            }
        }
    }
}
