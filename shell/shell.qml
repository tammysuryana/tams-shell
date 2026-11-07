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

    // Perintah dari luar:  qs -c tams ipc call tams launcher   (atau dashboard / wifi / settings / lock / close)
    IpcHandler {
        target: "tams"
        function launcher(): void { Panels.toggleLauncher() }
        function dashboard(): void { Panels.toggleDashboard() }
        function wifi(): void { Panels.openWifi() }
        function lock(): void { Panels.closeAll(); Power.lock() }
        function settings(): void { Panels.toggleSettings() }
        function close(): void { Panels.closeAll() }
    }

    // Shortcut global Hyprland:  bind = SUPER, Space, global, tams:launcher
    GlobalShortcut { appid: "tams"; name: "launcher"; description: "Buka/tutup launcher"; onPressed: Panels.toggleLauncher() }
    GlobalShortcut { appid: "tams"; name: "dashboard"; description: "Buka/tutup dashboard"; onPressed: Panels.toggleDashboard() }
    GlobalShortcut { appid: "tams"; name: "settings"; description: "Buka/tutup pengaturan"; onPressed: Panels.toggleSettings() }

    // Terapkan tampilan jendela (jarak, garis tepi, sudut, warna tepi, ...) ke Hyprland
    Binding { target: HyprLook; property: "activeBorder"; value: Theme.accent }
    Binding { target: HyprLook; property: "inactiveBorder"; value: Theme.line }
    Binding { target: HyprLook; property: "dark"; value: Theme.dark }
}
