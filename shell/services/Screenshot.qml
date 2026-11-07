pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Tangkap layar dengan grim (+ slurp untuk memilih area atau jendela).
// Disimpan ke folder screenshot (bawaan: ~/Pictures/Screenshots), disalin ke clipboard,
// lalu muncul notifikasi dengan pratinjau dan tombol Buka / Buka folder.
Singleton {
    id: root

    property string picturesDir: Quickshell.env("HOME") + "/Pictures"
    readonly property string dir: Settings.screenshotDir !== "" ? Settings.screenshotDir : picturesDir + "/Screenshots"
    property string _mode: ""

    // mode: "area" (seret kotak / klik jendela) | "screen" (layar yang aktif) | "all" (semua layar)
    function take(mode) {
        Panels.closeAll()
        root._mode = ["area", "screen", "all"].includes(mode) ? mode : "area"
        if (root._mode === "area") clients.running = true
        else run("")
    }

    function run(boxes) {
        const mon = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/screenshot.sh"), root.dir, root._mode, mon, boxes])
    }

    // Kotak jendela yang terlihat di workspace aktif tiap layar, supaya bisa diklik di slurp
    Process {
        id: clients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let boxes = ""
                try {
                    const ws = Hyprland.monitors.values.map(m => m.activeWorkspace ? m.activeWorkspace.id : null)
                    boxes = JSON.parse(text)
                        .filter(c => c.mapped && !c.hidden && ws.includes(c.workspace.id))
                        .map(c => `${c.at[0]},${c.at[1]} ${c.size[0]}x${c.size[1]}`)
                        .join("\n")
                } catch (e) { console.warn("Screenshot: " + e) }
                root.run(boxes)
            }
        }
    }

    Process {
        command: ["xdg-user-dir", "PICTURES"]
        running: true
        stdout: StdioCollector { onStreamFinished: if (text.trim() !== "") root.picturesDir = text.trim() }
    }
}
