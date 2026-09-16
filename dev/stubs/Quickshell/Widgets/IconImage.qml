import QtQuick

// Square icon drawn at its real pixel size. sourceSize is tied to the device pixel
// ratio so a 18pt icon is decoded at 36px on a retina screen rather than scaled up.
Item {
    id: root

    property alias source: image.source
    property alias asynchronous: image.asynchronous
    property int implicitSize: 16
    property bool mipmap: true
    property alias status: image.status

    implicitWidth: implicitSize
    implicitHeight: implicitSize

    Image {
        id: image

        anchors.fill: parent
        sourceSize.width: root.implicitSize * Screen.devicePixelRatio
        sourceSize.height: root.implicitSize * Screen.devicePixelRatio
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: root.mipmap
    }
}
