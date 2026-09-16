import QtQuick

QtObject {
    enum Reason {
        Unknown,
        NoSecrets,
        WifiAuthTimeout,
        WifiNetworkLost,
        DhcpFailed
    }
}
