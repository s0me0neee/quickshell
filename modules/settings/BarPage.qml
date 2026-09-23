import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

ColumnLayout {
    id: root

    spacing: Appearance.spacingLarge

    Section {
        title: "Status buttons"

        SettingRow {
            label: "Tray"
            description: "Hidden anyway when no app has put an icon there."

            Toggle {
                checked: Settings.data.showTray
                onToggled: {
                    Settings.data.showTray = !Settings.data.showTray;
                    Settings.save();
                }
            }
        }

        SettingRow {
            label: "Network"

            Toggle {
                checked: Settings.data.showNetwork
                onToggled: {
                    Settings.data.showNetwork = !Settings.data.showNetwork;
                    Settings.save();
                }
            }
        }

        SettingRow {
            label: "Volume"

            Toggle {
                checked: Settings.data.showVolume
                onToggled: {
                    Settings.data.showVolume = !Settings.data.showVolume;
                    Settings.save();
                }
            }
        }

        SettingRow {
            label: "Battery"
            description: "Only ever shown on a machine that has one."

            Toggle {
                checked: Settings.data.showBattery
                onToggled: {
                    Settings.data.showBattery = !Settings.data.showBattery;
                    Settings.save();
                }
            }
        }

        SettingRow {
            label: "Control centre"
            description: Settings.data.showControlCenter ? "" : "Turning this off leaves no way back to these settings except editing the file."

            Toggle {
                checked: Settings.data.showControlCenter
                onToggled: {
                    Settings.data.showControlCenter = !Settings.data.showControlCenter;
                    Settings.save();
                }
            }
        }
    }

    Section {
        title: "Clock"

        SettingRow {
            label: "Format"

            Choice {
                options: ["24h", "12h"]
                current: Settings.data.twelveHour ? 1 : 0
                onPicked: index => {
                    Settings.data.twelveHour = index === 1;
                    Settings.save();
                }
            }
        }

        SettingRow {
            label: "Hub opens on"
            description: "Which tab a right-click on the island shows first."

            Choice {
                readonly property var keys: ["media", "weather", "calendar", "system"]

                options: ["Media", "Weather", "Calendar", "System"]
                current: Math.max(0, keys.indexOf(Settings.data.hubTab))
                onPicked: index => {
                    Settings.data.hubTab = keys[index];
                    Settings.save();
                }
            }
        }
    }
}
