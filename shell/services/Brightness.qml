pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Kecerahan layar laptop lewat brightnessctl. Tidak tersedia di PC desktop (available = false).
Singleton {
    id: root

    property bool available: false
    property real value: 0      // 0..1

    signal changed()

    function set(v) {
        v = Math.max(0.01, Math.min(1, v))
        root.value = v
        setProc.command = ["brightnessctl", "-q", "set", Math.round(v * 100) + "%"]
        setProc.running = true
        root.changed()
    }

    Process {
        id: getProc
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                // format: nama,kelas,nilai,persen%,maks
                const p = text.trim().split("\n")[0].split(",")
                if (p.length >= 5) {
                    root.available = true
                    root.value = Number(p[2]) / Number(p[4])
                }
            }
        }
    }
    Process { id: setProc }
}
