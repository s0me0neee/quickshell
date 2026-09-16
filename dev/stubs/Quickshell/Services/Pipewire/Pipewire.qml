pragma Singleton

import QtQuick
import Preview

QtObject {
    id: root

    property PwNode preferredDefaultAudioSink: null
    property PwNode preferredDefaultAudioSource: null

    // The bluetooth scenario starts with the headset as the output, so the bar glyph can
    // be checked without clicking through the sound panel
    readonly property PwNode defaultAudioSink: preferredDefaultAudioSink ?? (Preview.scene("bluetooth") ? headphones : speakers)
    readonly property PwNode defaultAudioSource: preferredDefaultAudioSource ?? microphone

    readonly property var nodes: ({
            values: [speakers, headphones, microphone, firefoxStream, spotifyStream]
        })

    readonly property PwNode speakers: PwNode {
        name: "alsa_output.pci-0000_00_1f.3.analog-stereo"
        description: "Built-in Audio"
        volume: 0.55
    }

    readonly property PwNode headphones: PwNode {
        name: "bluez_output.AC_80_0A_1F_44_21.1"
        description: "WH-1000XM4"
        volume: 0.32
        properties: ({
                "device.api": "bluez5"
            })
    }

    readonly property PwNode microphone: PwNode {
        name: "alsa_input.pci-0000_00_1f.3.analog-stereo"
        description: "Built-in Microphone"
        isSink: false
        volume: 0.74
    }

    readonly property PwNode firefoxStream: PwNode {
        name: "Firefox"
        description: "Playback"
        isStream: true
        volume: 0.8
        properties: ({
                "application.name": "Firefox"
            })
    }

    readonly property PwNode spotifyStream: PwNode {
        name: "spotify"
        description: "Playback"
        isStream: true
        volume: 0.45
        properties: ({
                "application.name": "Spotify"
            })
    }
}
