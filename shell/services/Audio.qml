pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Volume speaker utama (PipeWire).
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.audio !== null
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false

    signal changed()

    function setVolume(v) {
        if (!ready) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1.5, v))
    }
    function toggleMute() { if (ready) sink.audio.muted = !sink.audio.muted }

    onVolumeChanged: root.changed()
    onMutedChanged: root.changed()

    PwObjectTracker { objects: [root.sink] }
}
