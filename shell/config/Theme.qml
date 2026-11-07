pragma Singleton

import QtQuick
import Quickshell
import qs.services

// Warna, ukuran, dan font tams-shell. Tema gelap/terang, sumber warna (pilihan sendiri atau dari
// wallpaper), aksen & tebal bingkai diatur dari panel Pengaturan (Super + I).
Singleton {
    id: root

    readonly property bool dark: Settings.mode !== "light"
    readonly property bool fromWallpaper: Settings.colorSource === "wallpaper" && WallColors.seed !== null
    // Gelap + warna pilihan sendiri = palet asli tams-shell; selain itu palet dibuat dari satu warna dasar
    readonly property bool classic: dark && !fromWallpaper
    readonly property color seed: fromWallpaper && WallColors.seed ? WallColors.seed : (Settings.accent || "#e0af68")
    readonly property real h: seed.hslHue < 0 ? 0 : seed.hslHue
    readonly property real s: seed.hslSaturation
    readonly property real ns: Math.min(s, 0.4) * 0.45          // saturasi warna netral (sedikit diwarnai)
    readonly property real h2: fromWallpaper && WallColors.seed2 ? WallColors.seed2.hslHue : (h + 0.14) % 1
    readonly property real s2: fromWallpaper && WallColors.seed2 ? WallColors.seed2.hslSaturation : s

    function tone(hue, sat, light) { return Qt.hsla(hue, sat, light, 1) }
    function clamp(v, a, b) { return Math.max(a, Math.min(b, v)) }

    // Bingkai & panel
    readonly property color frame: classic ? "#0f1117" : tone(h, ns, dark ? 0.075 : 0.965)
    readonly property color surface: classic ? "#171a22" : tone(h, ns, dark ? 0.11 : 0.925)
    readonly property color surface2: classic ? "#20242f" : tone(h, ns, dark ? 0.155 : 0.88)
    readonly property color line: classic ? "#2a2f3d" : tone(h, ns, dark ? 0.21 : 0.82)

    // Teks & aksen
    readonly property color text: classic ? "#d5d8e6" : tone(h, ns * 0.6, dark ? 0.88 : 0.15)
    readonly property color muted: classic ? "#7b8096" : tone(h, ns, dark ? 0.6 : 0.42)
    readonly property color accent: classic ? Settings.accent : tone(h, clamp(s, 0.45, 0.85), dark ? 0.7 : 0.42)
    readonly property color accent2: classic ? "#7dcfff" : tone(h2, clamp(s2, 0.4, 0.8), dark ? 0.74 : 0.38)
    readonly property color good: dark ? "#9ece6a" : "#4c7a1d"
    readonly property color warn: dark ? "#ff9e64" : "#b05300"
    readonly property color bad: dark ? "#f7768e" : "#c0304a"
    readonly property color hover: Qt.rgba(text.r, text.g, text.b, 0.04)

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
