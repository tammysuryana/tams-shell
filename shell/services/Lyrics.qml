pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

// Lirik musik tersinkron (karaoke) untuk pemutar MPRIS yang sedang aktif.
// Lirik diambil dari lrclib.net (gratis, tanpa kunci) lewat skrip Python.
// Menyediakan 7 "slot": 3 baris sebelum, baris aktif (indeks `before`), 3 sesudah.
Singleton {
    id: root

    // Pemutar aktif: yang sedang memutar; kalau tak ada, pemutar pertama.
    readonly property var player: {
        const p = Mpris.players.values
        for (let i = 0; i < p.length; i++) if (p[i].isPlaying) return p[i]
        return p.length > 0 ? p[0] : null
    }
    readonly property bool playing: root.player ? root.player.isPlaying : false

    property var lines: []           // [{ time, text }]
    property int activeIndex: -1
    property string status: "idle"   // idle | loading | ok | not_found | no_info
    property var slots: ["", "", "", "", "", "", ""]
    readonly property int before: 3
    readonly property int total: 7
    readonly property bool synced: status === "ok" && lines.length > 0

    function buildSlots(idx) {
        const r = []
        for (let i = 0; i < root.total; i++) {
            const li = idx - root.before + i
            r.push((li >= 0 && li < root.lines.length) ? (root.lines[li].text || "♪") : "")
        }
        return r
    }

    // Cari indeks baris lirik terakhir yang waktunya <= pos (binary search).
    function indexAt(pos) {
        const l = root.lines
        let lo = 0, hi = l.length - 1, res = -1
        while (lo <= hi) {
            const m = (lo + hi) >> 1
            if (l[m].time <= pos) { res = m; lo = m + 1 } else hi = m - 1
        }
        return res
    }

    function update() {
        if (!root.synced || !root.player) return
        const pos = root.player.position + 0.2   // sedikit mendahului agar terasa pas
        const idx = root.indexAt(pos)
        if (idx !== root.activeIndex) { root.activeIndex = idx; root.slots = root.buildSlots(idx) }
    }

    // Ganti lagu (judul/artis berubah) -> ambil lirik baru.
    readonly property string trackKey: root.player ? (root.player.trackTitle + "§" + root.player.trackArtist) : ""
    onTrackKeyChanged: root.fetch()

    function fetch() {
        proc.running = false
        root.lines = []
        root.activeIndex = -1
        root.slots = ["", "", "", "", "", "", ""]
        const title = root.player ? (root.player.trackTitle || "") : ""
        const artist = root.player ? (root.player.trackArtist || "") : ""
        const dur = root.player ? Math.round(root.player.length || 0) : 0
        if (!title || !artist) { root.status = "no_info"; return }
        root.status = "loading"
        proc.command = ["python3", Quickshell.shellPath("scripts/lyrics.py"), title, artist, String(dur)]
        proc.running = true
    }

    Process {
        id: proc
        stdout: SplitParser {
            onRead: data => {
                const t = data.trim()
                if (t === "not_found") { root.status = "not_found"; return }
                if (t === "no_info") { root.status = "no_info"; return }
                const parts = t.split("§")
                if (parts.length < 3 || parts[parts.length - 1].trim() !== "ok") return
                const lines = []
                for (let i = 0; i < parts.length - 1; i += 2) {
                    const tm = parseFloat(parts[i])
                    const tx = parts[i + 1] || ""
                    if (!isNaN(tm)) lines.push({ time: tm, text: tx })
                }
                if (lines.length === 0) { root.status = "not_found"; return }
                root.lines = lines
                root.activeIndex = -1
                root.slots = root.buildSlots(-1)
                root.status = "ok"
                root.update()
            }
        }
    }

    // Geser baris aktif selama memutar.
    Timer {
        interval: 250
        repeat: true
        running: root.synced && root.playing
        onTriggered: root.update()
    }
}
