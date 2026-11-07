pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Panel mana yang sedang terbuka, dan di layar mana (selalu layar yang sedang aktif).
Singleton {
    id: root

    property bool dashboard: false
    property bool launcher: false
    property bool settings: false
    property bool wifiList: false     // dashboard dibuka langsung dengan daftar WiFi terbuka
    property bool btList: false       // ... atau daftar Bluetooth
    property string screenName: ""

    signal pickWallpaper()   // buka pemilih file wallpaper (di layar yang aktif)

    function openWallpaperPicker() {
        root.screenName = activeScreen()
        closeAll()
        root.pickWallpaper()
    }

    function activeScreen() {
        return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    }

    function toggleDashboard() {
        root.screenName = activeScreen()
        root.launcher = false
        root.settings = false
        root.wifiList = false
        root.btList = false
        root.dashboard = !root.dashboard
    }

    function openWifi() {
        root.screenName = activeScreen()
        root.launcher = false
        root.settings = false
        root.btList = false
        root.dashboard = true
        root.wifiList = true
    }

    function openBluetooth() {
        root.screenName = activeScreen()
        root.launcher = false
        root.settings = false
        root.wifiList = false
        root.dashboard = true
        root.btList = true
    }

    function toggleLauncher() {
        root.screenName = activeScreen()
        root.dashboard = false
        root.settings = false
        root.wifiList = false
        root.btList = false
        root.launcher = !root.launcher
    }

    function closeAll() {
        root.dashboard = false
        root.launcher = false
        root.settings = false
        root.wifiList = false
        root.btList = false
    }

    function toggleSettings() {
        root.screenName = activeScreen()
        root.dashboard = false
        root.launcher = false
        root.wifiList = false
        root.btList = false
        root.settings = !root.settings
    }
}
