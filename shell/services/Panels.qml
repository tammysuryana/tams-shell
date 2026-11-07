pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Panel mana yang sedang terbuka, dan di layar mana (selalu layar yang sedang aktif).
Singleton {
    id: root

    property bool dashboard: false
    property bool launcher: false
    property bool wifiList: false     // dashboard dibuka langsung dengan daftar WiFi terbuka
    property string screenName: ""

    function activeScreen() {
        return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    }

    function toggleDashboard() {
        root.screenName = activeScreen()
        root.launcher = false
        root.wifiList = false
        root.dashboard = !root.dashboard
    }

    function openWifi() {
        root.screenName = activeScreen()
        root.launcher = false
        root.dashboard = true
        root.wifiList = true
    }

    function toggleLauncher() {
        root.screenName = activeScreen()
        root.dashboard = false
        root.wifiList = false
        root.launcher = !root.launcher
    }

    function closeAll() {
        root.dashboard = false
        root.launcher = false
        root.wifiList = false
    }
}
