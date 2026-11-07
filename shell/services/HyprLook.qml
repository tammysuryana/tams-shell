pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Menerapkan tampilan jendela dari Settings ke Hyprland yang sedang jalan (tanpa menyentuh file
// config Hyprland). Diterapkan lagi setiap kali config Hyprland dimuat ulang.
Singleton {
    id: root

    readonly property string look: [Settings.gapsIn, Settings.gapsOut, Settings.border, Settings.rounding,
        Settings.blur, Settings.animations, Settings.inactiveOpacity].join(",")
    onLookChanged: timer.restart()
    Component.onCompleted: timer.restart()

    function apply() {
        const s = Settings
        const op = s.inactiveOpacity.toFixed(2)
        if (Hyprland.usingLua) {
            const lua = "hl.config({ general = { gaps_in = " + s.gapsIn + ", gaps_out = " + s.gapsOut
                + ", border_size = " + s.border + " }, decoration = { rounding = " + s.rounding
                + ", inactive_opacity = " + op + ", blur = { enabled = " + s.blur + " } }"
                + ", animations = { enabled = " + s.animations + " } })"
            Quickshell.execDetached(["hyprctl", "eval", lua])
        } else {
            Quickshell.execDetached(["hyprctl", "--batch",
                "keyword general:gaps_in " + s.gapsIn + "; keyword general:gaps_out " + s.gapsOut
                + "; keyword general:border_size " + s.border + "; keyword decoration:rounding " + s.rounding
                + "; keyword decoration:inactive_opacity " + op
                + "; keyword decoration:blur:enabled " + s.blur + "; keyword animations:enabled " + s.animations])
        }
    }

    // Kumpulkan perubahan beruntun (mis. slider digeser) jadi satu panggilan hyprctl
    Timer { id: timer; interval: 60; onTriggered: root.apply() }

    Connections {
        target: Hyprland
        function onRawEvent(ev) { if (ev.name === "configreloaded") timer.restart() }
    }
}
