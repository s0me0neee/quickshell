import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// Now, the next twelve hours, and the week. Each day's bar sits on one scale shared by
// the whole week, so a warm day reads as warm next to the others, not just on its own.
ColumnLayout {
    id: root

    readonly property var columns: (Weather.hourly ?? []).slice(0, 12)
    readonly property var days: Weather.daily ?? []
    // The week's coldest low and warmest high, the two ends every bar is placed between
    // A loop, not flatMap: the list arrives as a QML sequence, which has no flatMap
    readonly property var temps: {
        const out = [];
        for (const d of days)
            for (const t of [d.high, d.low])
                if (t !== null && t !== undefined)
                    out.push(t);
        return out;
    }
    readonly property real weekMin: temps.length > 0 ? Math.min(...temps) : 0
    readonly property real weekMax: temps.length > 0 ? Math.max(...temps) : 1
    // Whether this page is on screen. The hub drives it; the fetch follows
    property bool active: false

    onActiveChanged: {
        if (active)
            Weather.watch();
        else
            Weather.unwatch();
    }

    Component.onDestruction: {
        if (active)
            Weather.unwatch();
    }

    function hourLabel(iso: string): string {
        return Settings.hour(new Date(iso));
    }

    // "2026-09-22" is a date where the forecast is, so it is built as a local date: a
    // Date parsed from the string alone is UTC midnight, the day before west of Greenwich
    function dayLabel(date: string): string {
        const [y, m, d] = date.split("-").map(Number);
        const day = new Date(y, m - 1, d);
        if (day.toDateString() === new Date().toDateString())
            return "Today";
        return Qt.locale().dayName(day.getDay(), Locale.ShortFormat);
    }

    function degrees(fahrenheit: var): string {
        return fahrenheit === null || fahrenheit === undefined ? "–" : `${Math.round(Settings.temperature(fahrenheit))}°`;
    }

    spacing: Appearance.spacingLarge

    // --- now, and the next twelve hours ---

    RowLayout {
        Layout.fillWidth: true
        visible: Weather.available
        spacing: Appearance.spacingLarge * 2

        ColumnLayout {
            Layout.preferredWidth: 220
            Layout.alignment: Qt.AlignTop
            spacing: 2

            RowLayout {
                spacing: Appearance.spacingLarge

                Icon {
                    text: Icons.weather(Weather.condition)
                    size: 52
                    color: Theme.primary
                }

                RowLayout {
                    spacing: 2

                    StyledText {
                        text: Math.round(Settings.temperature(Weather.now?.temperature ?? 0))
                        font.pixelSize: 44
                        font.weight: Font.Light
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignTop
                        Layout.topMargin: 8
                        text: `°${Settings.temperatureUnit}`
                        color: Theme.surfaceVariantText
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                text: Weather.summary
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: Weather.city
                elide: Text.ElideRight
                color: Theme.textDim
                font.pixelSize: Appearance.fontSizeSmall
            }

            // Wind and damp, the two numbers that change what you wear
            RowLayout {
                Layout.topMargin: Appearance.spacing
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
                    label: `${Math.round(Settings.wind(Weather.now?.wind ?? 0))} ${Settings.windUnit} ${Weather.now?.windDirection ?? ""}`
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Repeater {
                model: root.columns

                // A plain Item, not a ColumnLayout: a layout nested straight into another
                // layout sizes itself from its contents and ignores the width it was given
                Item {
                    id: column

                    required property var modelData

                    Layout.fillWidth: true
                    implicitHeight: stack.implicitHeight

                    ColumnLayout {
                        id: stack

                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 4

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
                            text: root.degrees(column.modelData.temperature)
                            font.pixelSize: Appearance.fontSizeSmall
                            font.weight: Font.DemiBold
                        }

                        StyledText {
                            Layout.alignment: Qt.AlignHCenter
                            // Blank rather than "0%": most hours have no chance at all
                            text: column.modelData.precipitation >= 20 ? `${Math.round(column.modelData.precipitation)}%` : " "
                            color: Theme.primary
                            font.pixelSize: Appearance.fontSizeSmall - 2
                        }
                    }
                }
            }
        }
    }

    Divider {
        visible: Weather.available && root.days.length > 0
    }

    // --- the week ---

    ColumnLayout {
        Layout.fillWidth: true
        visible: Weather.available && root.days.length > 0
        spacing: 2

        Repeater {
            model: root.days

            RowLayout {
                id: day

                required property var modelData
                readonly property real low: modelData.low ?? modelData.high ?? 0
                readonly property real high: modelData.high ?? modelData.low ?? 0

                Layout.fillWidth: true
                implicitHeight: 28
                spacing: Appearance.spacingLarge

                StyledText {
                    Layout.preferredWidth: 56
                    text: root.dayLabel(day.modelData.date)
                    font.weight: Font.DemiBold
                }

                Icon {
                    Layout.preferredWidth: 22
                    text: Icons.weather(day.modelData.condition)
                    size: 17
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    Layout.preferredWidth: 150
                    text: day.modelData.short ?? ""
                    elide: Text.ElideRight
                    color: Theme.surfaceVariantText
                    font.pixelSize: Appearance.fontSizeSmall
                }

                StyledText {
                    Layout.preferredWidth: 36
                    horizontalAlignment: Text.AlignRight
                    text: day.modelData.precipitation >= 20 ? `${Math.round(day.modelData.precipitation)}%` : ""
                    color: Theme.primary
                    font.pixelSize: Appearance.fontSizeSmall
                }

                StyledText {
                    Layout.preferredWidth: 36
                    horizontalAlignment: Text.AlignRight
                    text: root.degrees(day.modelData.low)
                    color: Theme.textDim
                }

                // The week's range as the track, this day's low-to-high as the fill
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 6

                    readonly property real span: Math.max(1, root.weekMax - root.weekMin)

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Qt.alpha(Theme.surfaceText, 0.1)
                    }

                    Rectangle {
                        x: parent.width * (day.low - root.weekMin) / parent.span
                        width: Math.max(height, parent.width * (day.high - day.low) / parent.span)
                        height: parent.height
                        radius: height / 2
                        color: Theme.primary
                    }
                }

                StyledText {
                    Layout.preferredWidth: 36
                    text: root.degrees(day.modelData.high)
                    font.weight: Font.DemiBold
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

    // When it was taken, so a stale page can be told from a fresh one. Click to refetch
    StyledText {
        Layout.fillWidth: true
        visible: Weather.available
        horizontalAlignment: Text.AlignRight
        text: `Updated ${Settings.time(Weather.updated)}`
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
