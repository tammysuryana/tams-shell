pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Menjaga symlink ~/.config/tams/lock agar menunjuk ke wallpaper layar kunci yang efektif:
// Settings.lockWallpaper bila diisi, kalau tidak ikut wallpaper desktop, kalau tidak wallpaper bawaan.
// hyprlock.conf membaca symlink ini, jadi ganti wallpaper = ganti layar kunci juga.
Singleton {
    id: root

    readonly property string target: Settings.lockWallpaper !== "" ? Settings.lockWallpaper
        : (Settings.wallpaperPath !== "" ? Settings.wallpaperPath : Settings.wallpaperFile)

    onTargetChanged: relink()
    Component.onCompleted: relink()

    function relink() {
        if (root.target === "") return
        linker.running = false
        linker.running = true
    }

    Process {
        id: linker
        // target lewat argumen ($1) agar aman untuk nama berisi spasi / karakter khusus
        command: ["sh", "-c",
            "mkdir -p \"$HOME/.config/tams\"; ln -sfn \"$1\" \"$HOME/.config/tams/lock\"",
            "sh", root.target]
    }
}
