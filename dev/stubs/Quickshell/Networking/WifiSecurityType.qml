import QtQuick

QtObject {
    enum Security {
        Open,
        Wep,
        WpaPsk,
        Wpa2Psk,
        Wpa3Psk,
        Sae,
        Owe,
        Enterprise
    }
}
