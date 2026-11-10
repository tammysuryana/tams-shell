//@ pragma UseQApplication
// tams-shell — shell Hyprland bergaya "bingkai". MIT License, (c) 2026 tams.
// Jalankan: qs -c tams

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.services
import qs.frame
import qs.config

ShellRoot {
    Variants {
        model: Quickshell.screens
        Frame {
            required property var modelData
            screen: modelData
        }
    }

    // Redupkan / kunci / matikan layar / tidur saat ditinggal
    IdleWatcher {}

    // Perintah dari luar:  qs -c tams ipc call tams launcher   (atau dashboard / wifi / bluetooth / audio / keys / screenshot area|screen|all / caffeine / settings / wallpaper / lock / close)
    IpcHandler {
        target: "tams"
        function launcher(): void { Panels.toggleLauncher() }
        function dashboard(): void { Panels.toggleDashboard() }
        function wifi(): void { Panels.openWifi() }
        function bluetooth(): void { Panels.openBluetooth() }
        function audio(): void { Panels.openAudio() }
        function keys(): void { Panels.toggleKeys() }
        function screenshot(mode: string): void { Screenshot.take(mode) }
        function caffeine(): void { Idle.caffeine = !Idle.caffeine }
        function lock(): void { Panels.closeAll(); Power.lock() }
        function settings(): void { Panels.toggleSettings() }
        function wallpaper(): void { Panels.openWallpaperPicker() }
        function close(): void { Panels.closeAll() }
    }

    // Shortcut global Hyprland:  bind = SUPER, Space, global, tams:launcher
    GlobalShortcut { appid: "tams"; name: "launcher"; description: "Buka/tutup launcher"; onPressed: Panels.toggleLauncher() }
    GlobalShortcut { appid: "tams"; name: "dashboard"; description: "Buka/tutup dashboard"; onPressed: Panels.toggleDashboard() }
    GlobalShortcut { appid: "tams"; name: "keys"; description: "Buka/tutup daftar pintasan"; onPressed: Panels.toggleKeys() }
    // Super ditekan sendiri lalu dilepas = launcher; tombol lain selama Super ditahan membatalkannya
    GlobalShortcut {
        appid: "tams"; name: "launcherTap"; description: "Super ditekan sendiri: launcher"
        onPressed: Panels.superTap = true
        onReleased: { if (Panels.superTap) Panels.toggleLauncher(); Panels.superTap = false }
    }
    GlobalShortcut { appid: "tams"; name: "launcherTapCancel"; description: "Batalkan launcher dari Super"; onPressed: Panels.superTap = false }
    GlobalShortcut { appid: "tams"; name: "lock"; description: "Kunci layar"; onPressed: { Panels.closeAll(); Power.lock() } }
    GlobalShortcut { appid: "tams"; name: "wallpaper"; description: "Pilih wallpaper"; onPressed: Panels.openWallpaperPicker() }
    GlobalShortcut { appid: "tams"; name: "theme"; description: "Ganti gelap / terang"; onPressed: Settings.set("mode", Settings.mode === "dark" ? "light" : "dark") }
    GlobalShortcut { appid: "tams"; name: "caffeine"; description: "Tetap menyala"; onPressed: Idle.caffeine = !Idle.caffeine }
    GlobalShortcut { appid: "tams"; name: "screenshotArea"; description: "Screenshot area / jendela"; onPressed: Screenshot.take("area") }
    GlobalShortcut { appid: "tams"; name: "screenshotScreen"; description: "Screenshot layar aktif"; onPressed: Screenshot.take("screen") }
    GlobalShortcut { appid: "tams"; name: "screenshotAll"; description: "Screenshot semua layar"; onPressed: Screenshot.take("all") }
    GlobalShortcut { appid: "tams"; name: "settings"; description: "Buka/tutup pengaturan"; onPressed: Panels.toggleSettings() }

    // Terapkan tampilan jendela (jarak, garis tepi, sudut, warna tepi, ...) ke Hyprland
    Binding { target: HyprLook; property: "activeBorder"; value: Theme.accent }
    Binding { target: HyprLook; property: "inactiveBorder"; value: Theme.line }
    Binding { target: HyprLook; property: "dark"; value: Theme.dark }
}
