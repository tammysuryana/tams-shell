pragma Singleton

import QtQuick
import Quickshell
import qs.services

// Warna, ukuran, dan font tams-shell. Aksen & tebal bingkai diatur dari panel Pengaturan (Super + I).
Singleton {
    // Bingkai & panel
    readonly property color frame: "#0f1117"
    readonly property color surface: "#171a22"
    readonly property color surface2: "#20242f"
    readonly property color line: "#2a2f3d"

    // Teks & aksen
    readonly property color text: "#d5d8e6"
    readonly property color muted: "#7b8096"
    readonly property color accent: Settings.accent
    readonly property color accent2: "#7dcfff"
    readonly property color good: "#9ece6a"
    readonly property color warn: "#ff9e64"
    readonly property color bad: "#f7768e"

    // Ukuran bingkai: tebal atas (berisi bar), tebal sisi, lengkung sudut dalam
    readonly property int barHeight: 44
    readonly property int edge: Settings.edge
    readonly property int radius: 22
    readonly property int panelRadius: 30

    // Font: Inter ikut dibawa shell (assets/fonts), angka & ikon pakai JetBrainsMono Nerd Font
    readonly property string font: interLoader.status === FontLoader.Ready ? interLoader.name : "sans-serif"
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 14

    // Durasi animasi (ms)
    readonly property int anim: 220

    FontLoader {
        id: interLoader
        source: Qt.resolvedUrl("../assets/fonts/InterVariable.ttf")
    }
}
