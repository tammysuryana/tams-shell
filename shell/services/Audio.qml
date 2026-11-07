pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Volume speaker utama (PipeWire) + pilihan keluaran suara (speaker, headphone, HDMI, Bluetooth).
// Keluaran dibaca dari kartu suara lewat pactl, karena di sebagian laptop (mis. Chromebook)
// headphone bukan sink tersendiri melainkan profil kartu yang harus diganti dulu.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.audio !== null
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false

    // [{ key, label, sub, kind: "speaker"|"headphones"|"hdmi", plugged, active, card, profile, port }]
    property var outputs: []
    readonly property var current: outputs.find(o => o.active) ?? null
    property var pending: null      // { card, port } yang sedang dipindah ke sana
    property var _sinks: []

    signal changed()

    function setVolume(v) {
        if (!ready) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1.5, v))
    }
    function toggleMute() { if (ready) sink.audio.muted = !sink.audio.muted }

    function select(o) {
        if (o.active) return
        root.pending = { card: o.card, port: o.port }
        pendingTimeout.restart()
        if (o.profile !== o.cardProfile) {
            run(["pactl", "set-card-profile", o.card, o.profile])
        } else {
            applyPending()
        }
    }

    // Sink kartu itu sudah ada: pilih port-nya, jadikan bawaan, pindahkan semua suara yang sedang main
    function applyPending() {
        const p = root.pending
        if (!p) return
        const s = root._sinks.find(s => s.properties["device.name"] === p.card && s.ports.some(sp => sp.name === p.port))
        if (!s) return    // profil baru belum selesai dibuat; tunggu event berikutnya
        root.pending = null
        pendingTimeout.stop()
        run(["sh", "-c", 'pactl set-sink-port "$1" "$2"; pactl set-default-sink "$1"; '
            + 'for i in $(pactl list short sink-inputs | cut -f1); do pactl move-sink-input "$i" "$1"; done',
            "sh", s.name, p.port])
    }

    function run(cmd) { Quickshell.execDetached(cmd); refreshDelay.restart() }

    function parse(cardsJson, sinksJson, defaultSink) {
        const cards = JSON.parse(cardsJson)
        const sinks = JSON.parse(sinksJson)
        const list = []
        for (const c of cards) {
            const bt = c.name.startsWith("bluez_card")
            const internal = c.properties["device.form_factor"] === "internal"
            const activeWords = c.active_profile.split(/[^\w-]+/)
            for (const pn in c.ports) {
                if (!(pn.startsWith("[Out]") || /output/i.test(pn))) continue
                const p = c.ports[pn]
                const type = (p.properties["port.type"] || p.type || "").toLowerCase()
                const kind = /head/.test(type) ? "headphones" : type === "hdmi" ? "hdmi" : "speaker"
                const plugged = p.availability !== "not available"
                const s = sinks.find(s => s.properties["device.name"] === c.name && s.ports.some(sp => sp.name === pn))
                const active = !!s && s.name === defaultSink && s.active_port === pn
                // Port yang tidak tercolok disembunyikan, kecuali headphone (deteksi colokan sering meleset)
                if (!plugged && kind !== "headphones" && !active) continue

                // Profil: yang aktif kalau sudah memuat port ini; kalau tidak, yang tersedia,
                // paling mirip profil sekarang (mis. tetap Mic1), lalu prioritas tertinggi.
                let profile = c.active_profile
                if (!p.profiles.includes(profile)) {
                    const score = n => n.split(/[^\w-]+/).filter(w => w && activeWords.includes(w)).length
                    profile = p.profiles
                        .filter(n => c.profiles[n])
                        .sort((a, b) => (c.profiles[b].available - c.profiles[a].available)
                            || (score(b) - score(a))
                            || (c.profiles[b].priority - c.profiles[a].priority))[0]
                    if (!profile) continue
                }

                let label = p.description
                if (bt) label = c.properties["device.description"] || label
                else if (kind === "hdmi" && p.properties["device.product.name"]) label = "HDMI · " + p.properties["device.product.name"]

                const sub = []
                if (!internal && !bt) sub.push(c.properties["device.description"] || c.name)
                if (!plugged) sub.push("Tidak tercolok")

                list.push({
                    key: c.name + "|" + pn, label: label, sub: sub.join(" · "), kind: kind,
                    plugged: plugged, active: active,
                    card: c.name, cardProfile: c.active_profile, profile: profile, port: pn
                })
            }
        }
        const rank = { speaker: 0, headphones: 1, hdmi: 2 }
        root.outputs = list.sort((a, b) => (b.plugged - a.plugged) || (rank[a.kind] - rank[b.kind]) || a.label.localeCompare(b.label))
        root._sinks = sinks
        applyPending()
    }

    function refresh() { readProc.running = true }

    Process {
        id: readProc
        command: ["sh", "-c", "pactl -f json list cards; echo; echo @@; pactl -f json list sinks; echo; echo @@; pactl get-default-sink"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const part = text.split("\n@@\n")
                if (part.length < 3) return
                try { root.parse(part[0], part[1], part[2].trim()) } catch (e) { console.warn("Audio: " + e) }
            }
        }
    }

    // Colok/cabut headphone, ganti profil, sink baru, ganti bawaan → baca ulang (dikumpulkan dulu)
    Process {
        id: subscribeProc
        command: ["pactl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: line => { if (/on (card|sink|server)\b(?!-)/.test(line)) refreshDelay.restart() }
        }
        onExited: restartSubscribe.start()
    }
    Timer { id: restartSubscribe; interval: 3000; onTriggered: subscribeProc.running = true }
    Timer { id: refreshDelay; interval: 150; onTriggered: root.refresh() }
    Timer { id: pendingTimeout; interval: 4000; onTriggered: root.pending = null }

    onVolumeChanged: root.changed()
    onMutedChanged: root.changed()

    PwObjectTracker { objects: [root.sink] }
}
