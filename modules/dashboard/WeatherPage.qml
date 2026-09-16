import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// Now, and the next few hours. Not a weather app: one glyph, one number, and enough of
// the afternoon to know whether to take a coat.
ColumnLayout {
    id: root

    // Every hour NOAA hands over, thinned to every other one — twelve columns in 300px
    // would be six pixels of text each
    readonly property var columns: (Weather.hourly ?? []).filter((h, i) => i % 2 === 0).slice(0, 5)

    function hourLabel(iso: string): string {
        return Qt.formatTime(new Date(iso), "HH");
    }

    spacing: Appearance.spacing

    // --- now ---

    RowLayout {
        Layout.fillWidth: true
        visible: Weather.available
        spacing: Appearance.spacingLarge

        Icon {
            text: Icons.weather(Weather.condition)
            size: 46
            color: Theme.primary
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                spacing: 2

                StyledText {
                    text: Weather.temperature
                    font.pixelSize: 34
                    font.weight: Font.Light
                }

                StyledText {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 6
                    text: `°${Weather.unit}`
                    color: Theme.surfaceVariantText
                    font.pixelSize: Appearance.fontSize
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: Weather.summary
                elide: Text.ElideRight
                color: Theme.surfaceText
                font.pixelSize: Appearance.fontSizeSmall
            }

            StyledText {
                Layout.fillWidth: true
                text: Weather.city
                elide: Text.ElideRight
                color: Theme.textDim
                font.pixelSize: Appearance.fontSizeSmall
            }
        }
    }

    // Wind and damp, the two numbers that change what you wear
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 2
        visible: Weather.available
        spacing: Appearance.spacingLarge

        Detail {
            icon: Icons.humidity
            label: `${Math.round(Weather.now?.humidity ?? 0)}%`
        }

        Detail {
            icon: Icons.rainy
            label: `${Math.round(Weather.now?.precipitation ?? 0)}%`
        }

        Detail {
            icon: Icons.windy
            label: `${Math.round(Weather.now?.wind ?? 0)} ${Weather.now?.windDirection ?? ""}`
        }

        Item {
            Layout.fillWidth: true
        }
    }

    Divider {
        visible: Weather.available && root.columns.length > 0
    }

    // --- the next few hours ---

    RowLayout {
        Layout.fillWidth: true
        visible: Weather.available && root.columns.length > 0
        spacing: 0

        Repeater {
            model: root.columns

            // A plain Item, not a ColumnLayout: a layout nested straight into another
            // layout sizes itself from its contents and ignores the width it was given,
            // which packed all five hours into the left third of the row
            Item {
                id: column

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: stack.implicitHeight

                ColumnLayout {
                    id: stack

                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 3

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.hourLabel(column.modelData.time)
                        color: Theme.surfaceVariantText
                        font.pixelSize: Appearance.fontSizeSmall - 1
                    }

                    Icon {
                        Layout.alignment: Qt.AlignHCenter
                        text: Icons.weather(column.modelData.condition)
                        size: 18
                        color: Theme.surfaceVariantText
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: `${Math.round(column.modelData.temperature)}°`
                        font.pixelSize: Appearance.fontSizeSmall
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }

    // --- nothing to show ---

    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacingLarge
        Layout.bottomMargin: Appearance.spacingLarge
        visible: !Weather.available
        spacing: Appearance.spacing

        Icon {
            Layout.alignment: Qt.AlignHCenter
            text: Weather.loading ? Icons.refresh : Icons.cloudy
            size: 28
            color: Theme.textDim
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: Weather.loading ? "Checking the sky…" : (Weather.error || "No forecast yet")
            color: Theme.textDim
            font.pixelSize: Appearance.fontSizeSmall
        }
    }

    // When it was taken, so a stale card can be told from a fresh one
    StyledText {
        Layout.fillWidth: true
        visible: Weather.available
        horizontalAlignment: Text.AlignRight
        text: `Updated ${Qt.formatTime(Weather.updated, "HH:mm")}`
        color: Theme.textDim
        font.pixelSize: Appearance.fontSizeSmall - 1

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Weather.refresh()
        }
    }

    component Detail: RowLayout {
        id: detail

        property string icon
        property string label

        spacing: Appearance.spacingSmall

        Icon {
            text: detail.icon
            size: 14
            color: Theme.surfaceVariantText
        }

        StyledText {
            text: detail.label
            color: Theme.surfaceVariantText
            font.pixelSize: Appearance.fontSizeSmall
        }
    }
}
