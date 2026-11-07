pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Layar: daftar monitor (hyprctl monitors all) dan menerapkan posisi / resolusi / skala dari
// Settings.displays ke Hyprland yang sedang jalan, tanpa menyentuh file config Hyprland.
// Diterapkan lagi saat config Hyprland dimuat ulang atau monitor dicolok.
//
// Settings.displays[nama] = { position, at, mode, scale }
//   position: "" (layar utama) | "left" | "right" | "up" | "down" | "custom" (pakai at = "XxY",
//             relatif terhadap layar utama) | "mirror" | "off"
Singleton {
    id: root

    // [{ name, label, internal, width, height, refresh, x, y, scale, mirrored, disabled, modes: [{ v, t }] }]
    property var monitors: []
    // Layar utama (patokan posisi): layar laptop kalau ada, kalau tidak monitor pertama
    readonly property var primary: monitors.find(m => m.internal) ?? monitors[0] ?? null
    // Perubahan yang menunggu dipertahankan; kalau dibiarkan, dikembalikan otomatis
    property var revert: null       // { prev: { nama: pengaturan }, secs }

    property bool _sync: true
    property var _applied: ({})     // nama → waktu terakhir diterapkan (cegah terapkan berulang)

    function refresh() { readProc.running = true }
    function find(name) { return root.monitors.find(m => m.name === name) ?? null }
    function isPrimary(name) { return root.primary !== null && root.primary.name === name }

    // Pengaturan tersimpan untuk satu layar, dilengkapi nilai bawaan / keadaan sekarang
    function conf(name) {
        const m = find(name)
        const pos = m ? placeOf(m) : ""
        return Object.assign({ position: pos === "only" ? "right" : pos, mode: "preferred", scale: "auto" }, Settings.displays[name] || {})
    }

    // Letak layar m: "" (utama) | "left" | "right" | "up" | "down" | "mirror" | "off" | "only" (layar utama mati)
    function placeOf(m) {
        if (m.disabled) return "off"
        if (m.mirrored) return "mirror"
        const a = root.primary
        if (!a || a.name === m.name) return ""
        if (a.disabled) return "only"
        const aw = a.width / a.scale, ah = a.height / a.scale
        const w = m.width / m.scale, h = m.height / m.scale
        if (m.x >= a.x + aw) return "right"
        if (m.x + w <= a.x) return "left"
        if (m.y + h <= a.y) return "up"
        if (m.y >= a.y + ah) return "down"
        return ""
    }

    // Ubah satu layar. confirm: tampilkan hitung mundur untuk kembali sendiri.
    function set(name, patch, confirm) {
        const changes = {}
        changes[name] = Object.assign(conf(name), patch)
        // Layar utama sedang mati dan posisi layar lain diubah: berarti kembali memakai dua layar
        const p = root.primary
        if (p && p.name !== name && p.disabled && "position" in patch)
            changes[p.name] = Object.assign(conf(p.name), { position: "" })
        commit(changes, confirm)
    }

    // Hanya layar ini yang menyala: layar utama dimatikan
    function only(name) {
        const p = root.primary
        const m = find(name)
        if (!p || !m || p.name === name) return
        const changes = {}
        const c = conf(name)
        if (c.position === "off" || c.position === "mirror") c.position = "right"
        changes[name] = c
        changes[p.name] = Object.assign(conf(p.name), { position: "off" })
        commit(changes, true)
        // Panel Pengaturan pindah ke layar yang tetap menyala (tombol Pertahankan ada di sana)
        Panels.screenName = name
        Panels.settings = true
    }

    // Tempatkan layar di posisi bebas hasil seret (rx, ry relatif ke layar utama, piksel logis):
    // menempel ke tepi terdekat, sejajar atas/tengah/bawah kalau dekat (tol piksel)
    function place(name, rx, ry, tol) {
        const p = root.primary, m = find(name)
        if (!p || !m) return
        const pw = p.width / p.scale, ph = p.height / p.scale
        const w = m.width / m.scale, h = m.height / m.scale
        const ovY = Math.min(h, ph) * 0.1, ovX = Math.min(w, pw) * 0.1
        const cy = y => Math.max(-h + ovY, Math.min(ph - ovY, y))
        const cx = x => Math.max(-w + ovX, Math.min(pw - ovX, x))
        const cands = [
            { side: "v", x: pw, y: cy(ry) }, { side: "v", x: -w, y: cy(ry) },
            { side: "h", x: cx(rx), y: -h }, { side: "h", x: cx(rx), y: ph }
        ]
        const d = c => Math.hypot(c.x - rx, c.y - ry)
        const c = cands.reduce((a, b) => d(b) < d(a) ? b : a)
        if (c.side === "v") { for (const t of [0, (ph - h) / 2, ph - h]) if (Math.abs(c.y - t) < tol) { c.y = t; break } }
        else { for (const t of [0, (pw - w) / 2, pw - w]) if (Math.abs(c.x - t) < tol) { c.x = t; break } }
        set(name, { position: "custom", at: Math.round(c.x) + "x" + Math.round(c.y) })
    }

    function commit(changes, confirm) {
        const prev = {}
        for (const n in changes) prev[n] = Object.assign({}, Settings.displays[n] || conf(n))
        for (const n in changes) Settings.setDisplay(n, changes[n])
        apply(changes)
        root.revert = confirm ? { prev: prev, secs: 15 } : null
    }

    function keep() { root.revert = null }
    function undo() {
        const r = root.revert
        if (!r) return
        root.revert = null
        for (const n in r.prev) Settings.setDisplay(n, r.prev[n])
        apply(r.prev)
    }

    // Koordinat (piksel logis) untuk layar name dengan pengaturan d, dihitung dari ukuran layar
    // utama (selalu dipaku di 0,0) dan ukuran baru layar ini (resolusi/skala d). null = "auto".
    function target(name, d) {
        const p = root.primary, m = find(name)
        if (!p || !m || p.name === name) return null
        if (d.position === "custom" && d.at) {
            return d.at.split("x").map(Number)
        }
        if (!["left", "right", "up", "down"].includes(d.position)) return null
        const r = d.mode && d.mode !== "preferred" ? /^(\d+)x(\d+)/.exec(d.mode) : null
        const sc = d.scale === "auto" ? m.scale : Number(d.scale)
        const w = (r ? Number(r[1]) : m.width) / sc, h = (r ? Number(r[2]) : m.height) / sc
        const pw = p.width / p.scale, ph = p.height / p.scale
        if (!w || !h || !pw || !ph) return null
        const xy = { right: [pw, 0], left: [-w, 0], up: [(pw - w) / 2, -h], down: [(pw - w) / 2, ph] }[d.position]
        return xy.map(Math.round)
    }

    // Perintah Hyprland untuk satu layar: { lua, kw }
    function spec(name, d) {
        const p = root.primary
        const isP = isPrimary(name)
        if (d.position === "off")
            return { lua: `hl.monitor({ output = ${JSON.stringify(name)}, disabled = true })`, kw: `keyword monitor ${name},disable` }
        const t = target(name, d)
        const pos = isP ? "0x0" : t ? t[0] + "x" + t[1] : "auto"
        const mirror = d.position === "mirror" && p && !isP ? p.name : ""
        const scale = d.scale === "auto" ? "auto" : Number(d.scale)
        const q = JSON.stringify
        return {
            lua: `hl.monitor({ output = ${q(name)}, mode = ${q(d.mode)}, position = ${q(pos)}, scale = ${q(scale)}, mirror = ${q(mirror)}, disabled = false })`,
            kw: `keyword monitor ${name},${d.mode},${pos},${scale}` + (mirror ? `,mirror,${mirror}` : "")
        }
    }

    // Terapkan { nama: pengaturan } dalam satu panggilan hyprctl. Yang dinyalakan lebih dulu dari
    // yang dimatikan, supaya tidak pernah semua layar mati.
    function apply(changes) {
        // Layar utama selalu ikut dipaku di 0,0. Kalau dibiarkan "auto", Hyprland menggesernya ke
        // sebelah layar yang baru diberi posisi, dan semua posisi jadi bergeser.
        const p = root.primary
        if (Object.keys(changes).length && p && !p.disabled && !(p.name in changes)) {
            changes = Object.assign({}, changes)
            changes[p.name] = conf(p.name)
        }
        const names = Object.keys(changes).sort((a, b) => (changes[a].position === "off") - (changes[b].position === "off"))
        if (!names.length) return
        const specs = names.map(n => spec(n, changes[n]))
        names.forEach((n, i) => root._applied[n] = { s: specs[i].lua, t: Date.now() })
        Quickshell.execDetached(Hyprland.usingLua ? ["hyprctl", "eval", specs.map(x => x.lua).join("; ")]
            : ["hyprctl", "--batch", specs.map(x => x.kw).join(" ; ")])
        // Baca ulang lalu cocokkan lagi (mis. posisi menyesuaikan ukuran baru setelah ganti resolusi)
        root._sync = true
        refreshDelay.interval = 1200
        refreshDelay.restart()
    }

    // Apakah keadaan layar m belum sesuai pengaturan d
    function differs(m, d) {
        if (d.position === "off") return !m.disabled
        if (m.disabled) return true
        if ((d.position === "mirror") !== m.mirrored) return true
        if (d.mode && d.mode !== "preferred") {
            const [res, hz] = d.mode.split("@")
            if (res !== m.width + "x" + m.height || (hz && Math.abs(Number(hz) - m.refresh) > 0.5)) return true
        }
        if (d.scale !== "auto" && Math.abs(Number(d.scale) - m.scale) > 0.01) return true
        const p = root.primary
        if (p && p.name === m.name) return m.x !== 0 || m.y !== 0
        const t = p && !p.disabled ? target(m.name, d) : null
        if (t && (Math.abs(m.x - t[0]) > 1 || Math.abs(m.y - t[1]) > 1)) return true
        return false
    }

    function sync() {
        const now = Date.now()
        const p = root.primary
        // Pengaman: jangan sampai semua layar mati (mis. HDMI dicabut waktu "hanya HDMI")
        if (p && root.monitors.every(m => m.disabled)) {
            const c = Object.assign(conf(p.name), { position: "" })
            Settings.setDisplay(p.name, c)
            const ch = {}
            ch[p.name] = c
            apply(ch)
            return
        }
        const changes = {}
        for (const name in Settings.displays) {
            const m = find(name)
            const d = conf(name)
            if (!m || !differs(m, d)) continue
            // Perintah yang sama baru saja dikirim: tunggu, jangan diulang terus
            const last = root._applied[name]
            if (last && last.s === spec(name, d).lua && now - last.t < 3000) continue
            // Layar utama hanya dimatikan kalau ada layar lain yang menyala
            if (isPrimary(name) && d.position === "off"
                && !root.monitors.some(o => o.name !== name && conf(o.name).position !== "off")) continue
            changes[name] = d
        }
        apply(changes)
    }

    function parse(json) {
        // Keluaran semu Hyprland (FALLBACK / HEADLESS saat tidak ada layar) bukan layar sungguhan
        const list = JSON.parse(json).filter(m => !/^(FALLBACK|HEADLESS)/.test(m.name)).map(m => {
            // Mode unik per resolusi (refresh tertinggi), besar → kecil
            const best = {}
            for (const s of m.availableModes || []) {
                const r = /^(\d+)x(\d+)@([\d.]+)/.exec(s)
                if (!r) continue
                const key = r[1] + "x" + r[2]
                if (!best[key] || Number(r[3]) > best[key].hz) best[key] = { w: Number(r[1]), h: Number(r[2]), hz: Number(r[3]) }
            }
            const modes = Object.values(best)
                .sort((a, b) => b.w * b.h - a.w * a.h || b.hz - a.hz)
                .map(o => ({ v: `${o.w}x${o.h}@${o.hz.toFixed(2)}`, t: `${o.w} × ${o.h} · ${Math.round(o.hz)} Hz`, w: o.w, h: o.h }))
            const internal = /^(eDP|LVDS|DSI)/.test(m.name)
            return {
                name: m.name,
                label: internal ? "Layar laptop" : (m.model || m.description || m.name),
                internal: internal,
                width: m.width, height: m.height, refresh: m.refreshRate,
                x: m.x, y: m.y, scale: m.scale,
                mirrored: m.mirrorOf !== undefined && m.mirrorOf !== "none",
                disabled: !!m.disabled,
                modes: modes
            }
        })
        root.monitors = list
        if (root._sync) {
            root._sync = false
            sync()
        }
    }

    Process {
        id: readProc
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.parse(text) } catch (e) { console.warn("Displays: " + e) } }
        }
    }

    Timer { id: refreshDelay; interval: 500; onTriggered: root.refresh() }

    Timer {
        interval: 1000
        repeat: true
        running: root.revert !== null
        onTriggered: {
            if (root.revert.secs <= 1) root.undo()
            else root.revert = Object.assign({}, root.revert, { secs: root.revert.secs - 1 })
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (ev.name === "configreloaded") root._applied = ({})
            if (ev.name === "configreloaded" || ev.name.startsWith("monitoradded") || ev.name.startsWith("monitorremoved")) {
                root._sync = true
                refreshDelay.interval = 500
                refreshDelay.restart()
            }
            // Monitor hilang: periksa sekali lagi setelah Hyprland selesai menata ulang, supaya
            // pengaman "jangan sampai semua layar mati" tidak terlewat
            if (ev.name.startsWith("monitorremoved")) recheck.restart()
        }
    }

    Timer { id: recheck; interval: 2500; onTriggered: { root._sync = true; root.refresh() } }

    Component.onCompleted: refresh()
}
