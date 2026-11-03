pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Kunci, keluar, ulang, matikan.
Singleton {
    function lock() { Quickshell.execDetached(["sh", "-c", "loginctl lock-session || hyprlock"]) }
    function logout() { Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.exit()" : "exit") }
    function reboot() { Quickshell.execDetached(["systemctl", "reboot"]) }
    function poweroff() { Quickshell.execDetached(["systemctl", "poweroff"]) }
}
