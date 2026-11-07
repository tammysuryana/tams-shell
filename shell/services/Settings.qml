pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Pengaturan pengguna di ~/.config/tams/settings.json (dibuat otomatis kalau belum ada).
// Diubah lewat panel Pengaturan (Super + I) atau langsung di file; perubahan langsung dipakai.
Singleton {
    id: root

    readonly property string defaultWallpaper: Qt.resolvedUrl("../assets/wallpaper.jpg")
    readonly property string wallpaper: adapter.wallpaper !== "" ? "file://" + adapter.wallpaper : defaultWallpaper
    readonly property string wallpaperPath: adapter.wallpaper
    // Path file biasa (bawaan pun), untuk yang tidak bisa membaca alamat qs: seperti ColorQuantizer
    readonly property string wallpaperFile: adapter.wallpaper !== "" ? adapter.wallpaper : Quickshell.shellPath("assets/wallpaper.jpg")
    readonly property string terminal: adapter.terminal
    readonly property string screenshotDir: adapter.screenshotDir   // kosong = ~/Pictures/Screenshots
    readonly property int workspaces: adapter.workspaces
    readonly property string workspaceStyle: adapter.workspaceStyle   // "number" | "dot" | "roman" | "kanji"

    // Tampilan shell
    readonly property string mode: adapter.mode                 // "dark" | "light"
    readonly property string colorSource: adapter.colorSource   // "manual" | "wallpaper"
    readonly property color accent: adapter.accent
    readonly property int edge: adapter.edge

    // Tampilan jendela Hyprland (diterapkan oleh HyprLook)
    readonly property int gapsIn: adapter.gapsIn
    readonly property int gapsOut: adapter.gapsOut
    readonly property int border: adapter.border
    readonly property int rounding: adapter.rounding
    readonly property bool blur: adapter.blur
    readonly property bool animations: adapter.animations
    readonly property real inactiveOpacity: adapter.inactiveOpacity

    // Saat ditinggal (detik tanpa sentuhan, 0 = tidak dipakai; dijalankan oleh Idle)
    readonly property int idleDim: adapter.idleDim
    readonly property int idleLock: adapter.idleLock
    readonly property int idleScreenOff: adapter.idleScreenOff
    readonly property int idleSuspend: adapter.idleSuspend
    readonly property bool lockOnSleep: adapter.lockOnSleep

    // Layar (diterapkan oleh Displays): { "HDMI-A-1": { position, mode, scale }, ... }
    readonly property var displays: adapter.displays

    readonly property var defaults: ({
        mode: "dark", colorSource: "manual", accent: "#e0af68", edge: 10, workspaces: 5, workspaceStyle: "number", terminal: "kitty",
        gapsIn: 2, gapsOut: 2, border: 2, rounding: 12,
        blur: true, animations: true, inactiveOpacity: 1.0
    })

    function setWallpaper(path) { adapter.wallpaper = path }
    function set(key, value) { if (adapter[key] !== value) adapter[key] = value }
    function setScreenshotDir(path) { adapter.screenshotDir = path }
    function setDisplay(name, patch) {
        const all = Object.assign({}, adapter.displays)
        all[name] = Object.assign({}, all[name], patch)
        adapter.displays = all
    }
    function resetLook() {
        for (const k in root.defaults)
            if (k !== "terminal") adapter[k] = root.defaults[k]
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/tams/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) writeAdapter() }

        JsonAdapter {
            id: adapter
            property string wallpaper: ""
            property string terminal: "kitty"
            property string screenshotDir: ""
            property int workspaces: 5
            property string workspaceStyle: "number"
            property string mode: "dark"
            property string colorSource: "manual"
            property string accent: "#e0af68"
            property int edge: 10
            property int gapsIn: 2
            property int gapsOut: 2
            property int border: 2
            property int rounding: 12
            property bool blur: true
            property bool animations: true
            property real inactiveOpacity: 1.0
            property var displays: ({})
            property int idleDim: 0
            property int idleLock: 300
            property int idleScreenOff: 600
            property int idleSuspend: 0
            property bool lockOnSleep: true
        }
    }
}
