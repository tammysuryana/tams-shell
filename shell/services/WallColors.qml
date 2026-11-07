pragma Singleton

import QtQuick
import Quickshell

// Warna utama wallpaper: gambar dikecilkan lalu dibagi jadi 16 kelompok warna (ColorQuantizer
// bawaan Quickshell, tanpa paket tambahan). Dari situ dipilih warna yang paling kuat & paling
// banyak muncul sebagai `seed`, dan warna kedua dengan rona berbeda sebagai `seed2`.
Singleton {
    id: root

    readonly property var colors: quant.colors
    readonly property bool ready: colors.length > 0
    // null kalau wallpaper hampir tanpa warna (abu-abu/hitam-putih)
    readonly property var seed: pick(colors, -1)
    readonly property var seed2: seed ? pick(colors, seed.hslHue) : null

    function hueDist(a, b) { const d = Math.abs(a - b); return Math.min(d, 1 - d) }

    // Pilih warna dengan skor tertinggi: saturasi × banyaknya kelompok lain yang ronanya mirip.
    // avoidHue >= 0: lewati warna yang ronanya terlalu dekat dengan avoidHue.
    function pick(list, avoidHue) {
        const cand = []
        for (let i = 0; i < list.length; i++) {
            const c = list[i]
            if (c.hslSaturation > 0.18 && c.hslLightness > 0.15 && c.hslLightness < 0.88) cand.push(c)
        }
        let best = null, bestScore = 0
        for (const c of cand) {
            if (avoidHue >= 0 && hueDist(c.hslHue, avoidHue) < 0.11) continue
            let near = 0
            for (const o of cand) if (hueDist(o.hslHue, c.hslHue) < 0.1) near++
            const score = c.hslSaturation * (0.6 + 0.4 * Math.min(1, c.hslLightness * 2)) * near
            if (score > bestScore) { bestScore = score; best = c }
        }
        return best
    }

    ColorQuantizer {
        id: quant
        source: Settings.colorSource === "wallpaper" ? "file://" + Settings.wallpaperFile : ""
        depth: 4
        rescaleSize: 96
    }
}
