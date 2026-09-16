import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.components
import qs.services

// One app's notifications in the list. A single notification is drawn exactly as it was
// before — the header and the fold only appear once an app has sent more than one, which
// is the only time grouping earns its space.
ColumnLayout {
    id: root

    required property string app
    required property list<NotifEntry> entries
    property bool expanded: false

    readonly property bool grouped: entries.length > 1
    readonly property string appIconPath: {
        const icon = entries.find(e => e.appIcon !== "")?.appIcon ?? "";
        return icon === "" ? "" : Quickshell.iconPath(icon, true);
    }

    signal toggled

    spacing: Appearance.spacingSmall

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Appearance.spacingSmall
        Layout.rightMargin: Appearance.spacingSmall
        visible: root.grouped
        spacing: Appearance.spacing

        IconImage {
            visible: root.appIconPath !== ""
            implicitSize: Appearance.themeIconSizeSmall
            asynchronous: true
            source: root.appIconPath
        }

        StyledText {
            Layout.fillWidth: true
            text: root.app
            color: Theme.surfaceVariantText
            font.pixelSize: Appearance.fontSizeSmall
            font.weight: Font.DemiBold
        }

        // Tapping the count is the same as tapping the chevron, so the whole right-hand
        // side of the header behaves as one control
        MouseArea {
            implicitWidth: countRow.implicitWidth + 10
            implicitHeight: 20
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggled()

            RowLayout {
                id: countRow

                anchors.centerIn: parent
                spacing: 2

                StyledText {
                    text: root.entries.length
                    color: Theme.surfaceVariantText
                    font.pixelSize: Appearance.fontSizeSmall
                    font.weight: Font.Bold
                }

                Icon {
                    text: Icons.chevronDown
                    size: 14
                    color: Theme.surfaceVariantText
                    rotation: root.expanded ? 180 : 0

                    Behavior on rotation {
                        Anim {
                            duration: Appearance.animNormal
                            easing.bezierCurve: Appearance.curveEmphasized
                        }
                    }
                }
            }
        }

        CircleButton {
            implicitWidth: 20
            implicitHeight: 20
            icon: Icons.close
            iconSize: 11
            fill: "transparent"
            iconColor: Theme.surfaceVariantText
            tooltip: `Clear ${root.app}`
            onClicked: Notifs.clearApp(root.app)
        }
    }

    // The newest one is always on show; the rest fold away behind the header
    NotifCard {
        Layout.fillWidth: true
        entry: root.entries[0]
        inList: true
        showAppName: !root.grouped
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: rest.implicitHeight * fold
        clip: true
        visible: root.grouped && implicitHeight > 0

        // Height is driven from this rather than animated directly, so the column below
        // always matches the space actually taken
        property real fold: root.expanded ? 1 : 0

        Behavior on fold {
            Anim {
                duration: Appearance.animNormal
                easing.bezierCurve: Appearance.curveEmphasized
            }
        }

        ColumnLayout {
            id: rest

            width: parent.width
            height: implicitHeight
            // Slides up behind the card above as it folds away, rather than shrinking
            y: -(1 - parent.fold) * implicitHeight
            // Zero, so each card carries its own leading gap and the gap folds with it
            spacing: 0

            Repeater {
                model: root.grouped ? root.entries.slice(1) : []

                NotifCard {
                    required property NotifEntry modelData

                    Layout.fillWidth: true
                    Layout.topMargin: Appearance.spacing
                    entry: modelData
                    inList: true
                    showAppName: false
                }
            }
        }
    }
}
