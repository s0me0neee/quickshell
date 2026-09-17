import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// Hangs under the clock, where you already look for the date.
//
// One page at a time, switched by the strip at the top — a dashboard that showed all
// three at once would be a wall. Pages are kept alive once visited rather than rebuilt
// on every switch, so flicking between them doesn't re-run the calendar's layout or
// lose the month you had paged to; the System page still stops reading /proc the moment
// it is not the one on show.
Popout {
    id: root

    // Bound to the shell clock from outside, so "today" survives midnight
    property date today: new Date()
    // Where it opens; flicking between tabs moves it, and closing puts it back
    property int page: Settings.data.dashboardTab

    contentWidth: 320

    Connections {
        target: root

        function onOpenChanged(): void {
            if (!root.open) {
                calendar.toToday();
                root.page = Settings.data.dashboardTab;
            }
        }
    }

    TabStrip {
        Layout.fillWidth: true

        model: [
            {
                icon: Icons.calendar,
                label: "Calendar"
            },
            {
                icon: Icons.weather(Weather.condition),
                label: "Weather"
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
        Layout.topMargin: Appearance.spacingSmall
        implicitHeight: [calendar, weather, system][root.page]?.implicitHeight ?? 0
        clip: true

        CalendarPage {
            id: calendar

            width: parent.width
            today: root.today
            visible: root.page === 0
        }

        WeatherPage {
            id: weather

            width: parent.width
            visible: root.page === 1
        }

        SystemPage {
            id: system

            width: parent.width
            // Only while it is both the page on show and on screen at all: a closed
            // dashboard must not leave a timer reading /proc every two seconds
            active: root.page === 2 && root.visible
            visible: root.page === 2
        }
    }
}
