pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Pengaturan pengguna di ~/.config/tams/settings.json (dibuat otomatis kalau belum ada).
Singleton {
    id: root

    readonly property string defaultWallpaper: Qt.resolvedUrl("../assets/wallpaper.jpg")
    readonly property string wallpaper: adapter.wallpaper !== "" ? "file://" + adapter.wallpaper : defaultWallpaper
    readonly property string terminal: adapter.terminal
    readonly property int workspaces: adapter.workspaces

    function setWallpaper(path) { adapter.wallpaper = path }

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
            property int workspaces: 5
        }
    }
}
