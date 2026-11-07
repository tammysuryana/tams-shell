pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Kunci, keluar, ulang, matikan.
Singleton {
    // Jalankan hyprlock langsung: "loginctl lock-session" selalu berhasil walau tidak ada yang
    // mendengar (hypridle tidak jalan), jadi layar tidak pernah terkunci. Tanpa hyprlock.conf
    // milik user, pakai contoh bawaan paket hyprlock.
    function lock() {
        Quickshell.execDetached(["sh", "-c",
            "pidof hyprlock >/dev/null && exit 0; " +
            "command -v hyprlock >/dev/null || exec loginctl lock-session; " +
            "c=\"${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock.conf\"; " +
            "if [ ! -f \"$c\" ] && [ -f /usr/share/hypr/hyprlock.conf ]; then exec hyprlock -c /usr/share/hypr/hyprlock.conf; fi; " +
            "exec hyprlock"])
    }
    function logout() { Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.exit()" : "exit") }
    function reboot() { Quickshell.execDetached(["systemctl", "reboot"]) }
    function poweroff() { Quickshell.execDetached(["systemctl", "poweroff"]) }
}
