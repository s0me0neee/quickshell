import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components
import qs.services

// Hangs under the clock, where you already look for the date.
//
// One page at a time, switched by the strip at the top — a dashboard that showed all
// three at once would be a wall. Pages are created on first selection and kept alive for
// the rest of this open panel, so switching tabs does not rebuild what you already saw.
Popout {
    id: root

    // Bound to the shell clock from outside, so "today" survives midnight
    property date today: new Date()
    // Where it opens; flicking between tabs moves it, and closing puts it back
    property int page: Settings.data.dashboardTab
    property bool calendarVisited: false
    property bool weatherVisited: false
    property bool systemVisited: false

    contentWidth: 320

    // The reset waits for `visible`, not `open`: the close is a fade, and putting the
    // page back as `open` drops would flash the calendar in while the panel is still
    // fading out. Only once the surface is gone does the page go back where it started.
    Connections {
        target: root

        function onVisibleChanged(): void {
            if (!root.visible) {
                calendarLoader.item?.toToday();
                root.calendarVisited = false;
                root.weatherVisited = false;
                root.systemVisited = false;
                root.page = Settings.data.dashboardTab;
            }
        }
    }

    onPageChanged: {
        if (page === 0)
            calendarVisited = true;
        else if (page === 1)
            weatherVisited = true;
        else if (page === 2)
            systemVisited = true;
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
        implicitHeight: [calendarLoader, weatherLoader, systemLoader][root.page]?.item?.implicitHeight ?? 0
        clip: true

        Loader {
            id: calendarLoader

            width: parent.width
            active: root.visible && (root.page === 0 || root.calendarVisited)
            visible: root.page === 0

            sourceComponent: Component {
                CalendarPage {
                    width: calendarLoader.width
                    today: root.today
                }
            }
        }

        Loader {
            id: weatherLoader

            width: parent.width
            active: root.visible && (root.page === 1 || root.weatherVisited)
            visible: root.page === 1

            sourceComponent: Component {
                WeatherPage {
                    width: weatherLoader.width
                    active: root.page === 1 && root.visible
                }
            }
        }

        Loader {
            id: systemLoader

            width: parent.width
            active: root.visible && (root.page === 2 || root.systemVisited)
            visible: root.page === 2

            sourceComponent: Component {
                SystemPage {
                    width: systemLoader.width
                    // Only while it is both the page on show and on screen at all: a
                    // closed dashboard must not leave a timer reading /proc.
                    active: root.page === 2 && root.visible
                }
            }
        }
    }
}
