import QtQuick
import QtQuick.Layouts
import qs.common
import qs.components

// Month grid that drops out of the clock. Today is a filled dot, days from the
// neighbouring months are dimmed, and the whole grid slides sideways when the month
// changes. Scroll anywhere on it to page months, middle-click to come back to today.
Popout {
    id: root

    // Bound to the shell clock from outside, so "today" survives midnight
    property date today: new Date()
    // The month on show, held as plain numbers: date arithmetic across month ends is
    // easier to get right than juggling Date objects
    property int shownYear: today.getFullYear()
    property int shownMonth: today.getMonth()

    readonly property bool showingThisMonth: shownYear === today.getFullYear() && shownMonth === today.getMonth()
    readonly property var locale: Qt.locale()
    // Sunday = 0, matching both Qt's Locale and JavaScript's getDay()
    readonly property int firstDayOfWeek: locale.firstDayOfWeek
    // Blank cells before the 1st, so the 1st lands under its weekday
    readonly property int lead: (new Date(shownYear, shownMonth, 1).getDay() - firstDayOfWeek + 7) % 7

    readonly property int cell: 34

    function shift(delta: int): void {
        const d = new Date(shownYear, shownMonth + delta, 1);
        slide.from = delta > 0 ? 18 : -18;
        shownYear = d.getFullYear();
        shownMonth = d.getMonth();
        slide.restart();
    }

    function toToday(): void {
        if (showingThisMonth)
            return;
        const behind = shownYear < today.getFullYear() || (shownYear === today.getFullYear() && shownMonth < today.getMonth());
        slide.from = behind ? 18 : -18;
        shownYear = today.getFullYear();
        shownMonth = today.getMonth();
        slide.restart();
    }

    contentWidth: cell * 7

    // Closing puts it back on this month, so it never reopens somewhere in 2031.
    // Connections rather than an onOpenChanged handler here: a handler on the root
    // would replace the one Popout itself declares, and with it the bookkeeping that
    // closes other popouts.
    Connections {
        target: root

        function onOpenChanged(): void {
            if (!root.open)
                root.toToday();
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacingSmall

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                text: root.locale.standaloneMonthName(root.shownMonth, Locale.LongFormat)
                font.pixelSize: Appearance.fontSize + 2
                font.weight: Font.DemiBold
            }

            StyledText {
                text: root.shownYear
                color: Theme.surfaceVariantText
                font.pixelSize: Appearance.fontSizeSmall
            }
        }

        // Only worth showing once you have wandered off the current month
        Button {
            visible: !root.showingThisMonth
            text: "Today"
            onClicked: root.toToday()
        }

        CircleButton {
            implicitWidth: 26
            implicitHeight: 26
            icon: Icons.chevronLeft
            iconSize: 16
            onClicked: root.shift(-1)
        }

        CircleButton {
            implicitWidth: 26
            implicitHeight: 26
            icon: Icons.chevronRight
            iconSize: 16
            onClicked: root.shift(1)
        }
    }

    // Weekday initials, in the locale's own week order
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: Appearance.spacingSmall
        spacing: 0

        Repeater {
            model: 7

            StyledText {
                required property int index

                Layout.preferredWidth: root.cell
                horizontalAlignment: Text.AlignHCenter
                text: root.locale.standaloneDayName((root.firstDayOfWeek + index) % 7, Locale.NarrowFormat)
                color: Theme.surfaceVariantText
                font.pixelSize: Appearance.fontSizeSmall
                font.weight: Font.DemiBold
            }
        }
    }

    Item {
        id: gridBox

        Layout.fillWidth: true
        implicitHeight: grid.implicitHeight
        clip: true

        GridLayout {
            id: grid

            width: parent.width
            columns: 7
            columnSpacing: 0
            rowSpacing: 2

            Repeater {
                model: 42

                MouseArea {
                    id: day

                    required property int index
                    // One Date per cell; the lead offset walks back into the previous month
                    readonly property date date: new Date(root.shownYear, root.shownMonth, 1 - root.lead + index)
                    readonly property bool outside: date.getMonth() !== root.shownMonth
                    readonly property bool isToday: date.toDateString() === root.today.toDateString()

                    Layout.preferredWidth: root.cell
                    Layout.preferredHeight: root.cell
                    hoverEnabled: true

                    Rectangle {
                        anchors.centerIn: parent
                        width: root.cell - 4
                        height: width
                        radius: width / 2
                        color: day.isToday ? Theme.primary : day.containsMouse ? Theme.glassHover : "transparent"

                        Behavior on color {
                            CAnim {
                                duration: Appearance.animFast
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: day.date.getDate()
                            color: {
                                if (day.isToday)
                                    return Theme.primaryText;
                                if (day.outside)
                                    return Qt.alpha(Theme.surfaceText, 0.28);
                                return Theme.surfaceText;
                            }
                            font.pixelSize: Appearance.fontSizeSmall + 1
                            font.weight: day.isToday ? Font.Bold : Font.Normal
                        }
                    }
                }
            }
        }

        // The grid slides in from the side the new month came from
        NumberAnimation {
            id: slide

            target: grid
            property: "x"
            to: 0
            duration: Appearance.animNormal
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.curveEmphasized
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.MiddleButton
            onClicked: root.toToday()
            onWheel: event => root.shift(event.angleDelta.y > 0 ? -1 : 1)
        }
    }
}
