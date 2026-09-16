import QtQuick

QtObject {
    enum State {
        Disconnected,
        Connecting,
        Connected,
        Disconnecting,
        Failed
    }
}
