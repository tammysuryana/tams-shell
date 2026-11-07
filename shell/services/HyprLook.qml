pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Menerapkan tampilan jendela dari Settings ke Hyprland yang sedang jalan (tanpa menyentuh file
// config Hyprland). Diterapkan lagi setiap kali config Hyprland dimuat ulang.
// Warna garis tepi & gelap/terang diisi dari Theme oleh shell.qml.
Singleton {
    id: root

    property color activeBorder: "#e0af68"
    property color inactiveBorder: "#2a2f3d"
    property bool dark: true

    readonly property string look: [Settings.gapsIn, Settings.gapsOut, Settings.border, Settings.rounding,
        Settings.blur, Settings.animations, Settings.inactiveOpacity, activeBorder, inactiveBorder, dark].join(",")

    property var schemeSent: null

    function rgb(c) { return "rgb(" + c.toString().slice(1, 7) + ")" }
    onLookChanged: timer.restart()
    Component.onCompleted: timer.restart()

    function apply() {
        // Aplikasi GTK/Chromium/Electron ikut gelap/terang lewat portal (org.gnome.desktop.interface)
        if (root.schemeSent !== root.dark) {
            root.schemeSent = root.dark
            Quickshell.execDetached(["sh", "-c", "command -v gsettings >/dev/null && gsettings set "
                + "org.gnome.desktop.interface color-scheme " + (root.dark ? "prefer-dark" : "prefer-light")])
        }
        const s = Settings
        const op = s.inactiveOpacity.toFixed(2)
        if (Hyprland.usingLua) {
            const lua = "hl.config({ general = { gaps_in = " + s.gapsIn + ", gaps_out = " + s.gapsOut
                + ", border_size = " + s.border + ", col = { active_border = \"" + rgb(activeBorder)
                + "\", inactive_border = \"" + rgb(inactiveBorder) + "\" } }, decoration = { rounding = " + s.rounding
                + ", inactive_opacity = " + op + ", blur = { enabled = " + s.blur + " } }"
                + ", animations = { enabled = " + s.animations + " } })"
            Quickshell.execDetached(["hyprctl", "eval", lua])
        } else {
            Quickshell.execDetached(["hyprctl", "--batch",
                "keyword general:gaps_in " + s.gapsIn + "; keyword general:gaps_out " + s.gapsOut
                + "; keyword general:border_size " + s.border + "; keyword decoration:rounding " + s.rounding
                + "; keyword general:col.active_border " + rgb(activeBorder)
                + "; keyword general:col.inactive_border " + rgb(inactiveBorder)
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
