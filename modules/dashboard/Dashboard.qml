import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// The hub: a right-click on the island. Media, weather, calendar and system, one page at
// a time, switched by the strip at the top — all four at once would be a wall. Pages are
// created on first selection and kept alive for the rest of this open panel, so
// switching tabs does not rebuild what you already saw.
Popout {
    id: root

    // Bound to the shell clock from outside, so "today" survives midnight
    property date today: new Date()

    // Tab order, by the names Settings.data.hubTab stores
    readonly property int startPage: Math.max(0, ["media", "weather", "calendar", "system"].indexOf(Settings.data.hubTab))
    // Where it opens; flicking between tabs moves it, and closing puts it back
    property int page: startPage
    property var visited: ({})

    contentWidth: 720

    // The reset waits for `visible`, not `open`: the close is a fade, and putting the
    // page back as `open` drops would flash another page in while the panel fades out.
    // Connections rather than a handler, which would replace Popout's own
    Connections {
        target: root

        function onVisibleChanged(): void {
            if (!root.visible) {
                calendarLoader.item?.toToday();
                root.visited = {};
                root.page = root.startPage;
            }
        }
    }

    onPageChanged: visited = Object.assign({}, visited, {
        [page]: true
    })

    function wanted(index: int): bool {
        return visible && (page === index || visited[index] === true);
    }

    TabStrip {
        Layout.fillWidth: true

        model: [
            {
                icon: Icons.music,
                label: "Media"
            },
            {
                icon: Icons.weather(Weather.condition),
                label: "Weather"
            },
            {
                icon: Icons.calendar,
                label: "Calendar"
            },
            {
                icon: Icons.cpu,
                label: "System"
            }
        ]
        current: root.page
        onSelected: index => root.page = index
    }

    // Every page sits at the top-left of the same box, which is as tall as whichever one
    // is showing.
    //
    // The pages swap outright rather than cross-fading. The panel's height snaps when
    // the page changes — see Popout for why it cannot be animated — so a page fading out
    // would spend its last frames clipped to the incoming page's height, which reads
    // worse than no transition at all. The tab underline carries the motion instead.
    Item {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacing
        implicitHeight: [mediaLoader, weatherLoader, calendarLoader, systemLoader][root.page]?.item?.implicitHeight ?? 0
        clip: true

        Loader {
            id: mediaLoader

            width: parent.width
            active: root.wanted(0)
            visible: root.page === 0

            sourceComponent: Component {
                MediaCard {
                    width: mediaLoader.width
                    minHeight: 220
                    detailed: true
                    active: root.page === 0 && root.visible
                }
            }
        }

        Loader {
            id: weatherLoader

            width: parent.width
            active: root.wanted(1)
            visible: root.page === 1

            sourceComponent: Component {
                WeatherPage {
                    width: weatherLoader.width
                    active: root.page === 1 && root.visible
                }
            }
        }

        Loader {
            id: calendarLoader

            width: parent.width
            active: root.wanted(2)
            visible: root.page === 2

            sourceComponent: Component {
                RowLayout {
                    function toToday(): void {
                        calendar.toToday();
                    }

                    width: calendarLoader.width
                    spacing: Appearance.spacingLarge * 2

                    DateColumn {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        today: root.today
                    }

                    CalendarPage {
                        id: calendar

                        Layout.preferredWidth: 340
                        today: root.today
                    }
                }
            }
        }

        Loader {
            id: systemLoader

            width: parent.width
            active: root.wanted(3)
            visible: root.page === 3

            sourceComponent: Component {
                SystemPage {
                    width: systemLoader.width
                    // Only while it is both the page on show and on screen at all: a
                    // closed hub must not leave a timer reading /proc.
                    active: root.page === 3 && root.visible
                }
            }
        }
    }

    // The calendar tab's left half: the time large, the date spelled out, and the
    // weather in one line for anyone who opened this to decide on a coat
    component DateColumn: ColumnLayout {
        id: dates

        property date today

        spacing: 2

        StyledText {
            text: Settings.time(dates.today)
            color: Theme.primary
            font.pixelSize: 56
            font.weight: Font.Light
        }

        StyledText {
            text: Qt.formatDate(dates.today, "dddd")
            font.pixelSize: Appearance.fontSize + 4
            font.weight: Font.DemiBold
        }

        StyledText {
            text: Qt.formatDate(dates.today, "MMMM d, yyyy")
            color: Theme.surfaceVariantText
        }

        RowLayout {
            Layout.topMargin: Appearance.spacingLarge
            visible: Weather.available
            spacing: Appearance.spacing

            Icon {
                text: Icons.weather(Weather.condition)
                size: 18
                color: Theme.surfaceVariantText
            }

            StyledText {
                text: `${Math.round(Settings.temperature(Weather.now?.temperature ?? 0))}° · ${Weather.summary}`
                color: Theme.surfaceVariantText
                font.pixelSize: Appearance.fontSizeSmall
            }
        }
    }
}
