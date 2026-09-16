import QtQuick
import QtQuick.Layouts
import qs.common

// Single-line input with placeholder. `password` adds a show/hide toggle. shake() for errors.
Rectangle {
    id: root

    property alias text: input.text
    property string placeholder
    property bool password: false
    property bool revealed: false
    property bool invalid: false

    signal accepted

    function focusInput(): void {
        input.forceActiveFocus();
    }

    function shake(): void {
        shakeAnim.restart();
    }

    Layout.fillWidth: true
    implicitHeight: 36
    radius: Appearance.radiusItem
    color: Qt.alpha(Theme.surfaceContainerHighest, 0.7)
    border.width: input.activeFocus || invalid ? 1.5 : 1
    border.color: invalid ? Theme.critical : input.activeFocus ? Theme.primary : Qt.alpha(Theme.outline, 0.5)

    Behavior on border.color {
        CAnim {
            duration: Appearance.animFast
        }
    }

    transform: Translate {
        id: offset
    }

    SequentialAnimation {
        id: shakeAnim

        NumberAnimation { target: offset; property: "x"; to: -8; duration: 50 }
        NumberAnimation { target: offset; property: "x"; to: 7; duration: 70 }
        NumberAnimation { target: offset; property: "x"; to: -5; duration: 60 }
        NumberAnimation { target: offset; property: "x"; to: 3; duration: 50 }
        NumberAnimation { target: offset; property: "x"; to: 0; duration: 40 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Appearance.spacingLarge
        anchors.rightMargin: Appearance.spacing
        spacing: Appearance.spacing

        TextInput {
            id: input

            Layout.fillWidth: true
            color: Theme.surfaceText
            selectionColor: Qt.alpha(Theme.primary, 0.4)
            selectedTextColor: Theme.surfaceText
            font.family: Appearance.fontFamily
            font.pixelSize: Appearance.fontSize
            echoMode: root.password && !root.revealed ? TextInput.Password : TextInput.Normal
            passwordCharacter: "•"
            inputMethodHints: root.password ? Qt.ImhSensitiveData | Qt.ImhNoPredictiveText : Qt.ImhNone
            clip: true
            onAccepted: root.accepted()
            onTextChanged: root.invalid = false

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === ""
                text: root.placeholder
                color: Theme.textDim
            }
        }

        MouseArea {
            visible: root.password
            implicitWidth: 24
            implicitHeight: 24
            cursorShape: Qt.PointingHandCursor
            onClicked: root.revealed = !root.revealed

            Icon {
                anchors.centerIn: parent
                text: root.revealed ? Icons.eyeOff : Icons.eye
                size: 15
                color: Theme.surfaceVariantText
            }
        }
    }
}
