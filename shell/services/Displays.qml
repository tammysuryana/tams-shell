pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Layar: daftar monitor (hyprctl monitors all) dan menerapkan posisi / resolusi / skala dari
// Settings.displays ke Hyprland yang sedang jalan, tanpa menyentuh file config Hyprland.
// Diterapkan lagi saat config Hyprland dimuat ulang atau monitor dicolok.
Singleton {
    id: root

    // [{ name, label, internal, width, height, refresh, x, y, scale, mirrored, disabled, modes: [{ v, t }] }]
    property var monitors: []
    // Layar utama: layar laptop kalau ada, kalau tidak monitor pertama yang menyala
    readonly property var main: monitors.find(m => m.internal && !m.disabled) ?? monitors.find(m => !m.disabled && !m.mirrored) ?? null
    // Resolusi/skala baru menunggu dipertahankan; kalau dibiarkan, dikembalikan otomatis
    property var revert: null       // { name, prev, secs }

    property bool _sync: true
    property var _applied: ({})     // nama → waktu terakhir diterapkan (cegah terapkan berulang)

    function refresh() { readProc.running = true }

    // Pengaturan tersimpan untuk satu layar, dilengkapi nilai bawaan
    function conf(name) {
        return Object.assign({ position: "", mode: "preferred", scale: "auto" }, Settings.displays[name] || {})
    }

    // Letak layar m terhadap layar utama: "left" | "right" | "up" | "down" | "mirror" | "off" | ""
    function placeOf(m) {
        if (m.disabled) return "off"
        if (m.mirrored) return "mirror"
        const a = root.main
        if (!a || a.name === m.name) return ""
        const aw = a.width / a.scale, ah = a.height / a.scale
        const w = m.width / m.scale, h = m.height / m.scale
        if (m.x >= a.x + aw) return "right"
        if (m.x + w <= a.x) return "left"
        if (m.y + h <= a.y) return "up"
        if (m.y >= a.y + ah) return "down"
        return ""
    }

    function set(name, patch, confirm) {
        const m = root.monitors.find(x => x.name === name)
        if (!m) return
        // Belum pernah diatur: mulai dari keadaan sekarang
        const before = Object.assign({ position: placeOf(m), mode: "preferred", scale: "auto" }, Settings.displays[name] || {})
        const after = Object.assign({}, before, patch)
        Settings.setDisplay(name, after)
        apply(name, after)
        root.revert = confirm ? { name: name, prev: before, secs: 15 } : null
    }

    function keep() { root.revert = null }
    function undo() {
        const r = root.revert
        if (!r) return
        root.revert = null
        Settings.setDisplay(r.name, r.prev)
        apply(r.name, r.prev)
    }

    function apply(name, d) {
        const isMain = root.main && root.main.name === name
        const pos = isMain ? "0x0"
            : ({ right: "auto-right", left: "auto-left", up: "auto-center-up", down: "auto-center-down" })[d.position] || "auto"
        const mirror = d.position === "mirror" && root.main && !isMain ? root.main.name : ""
        const q = JSON.stringify
        let cmd
        if (Hyprland.usingLua) {
            const spec = d.position === "off" && !isMain
                ? `output = ${q(name)}, disabled = true`
                : `output = ${q(name)}, mode = ${q(d.mode)}, position = ${q(pos)}, `
                  + `scale = ${d.scale === "auto" ? q("auto") : Number(d.scale)}, mirror = ${q(mirror)}, disabled = false`
            cmd = ["hyprctl", "eval", `hl.monitor({ ${spec} })`]
        } else {
            const rule = d.position === "off" && !isMain ? `${name},disable`
                : `${name},${d.mode},${pos},${d.scale}` + (mirror ? `,mirror,${mirror}` : "")
            cmd = ["hyprctl", "keyword", "monitor", rule]
        }
        root._applied[name] = Date.now()
        Quickshell.execDetached(cmd)
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
        if (["left", "right", "up", "down"].includes(d.position) && placeOf(m) !== d.position) return true
        return false
    }

    function sync() {
        const now = Date.now()
        for (const name in Settings.displays) {
            const m = root.monitors.find(x => x.name === name)
            const d = conf(name)
            if (m && differs(m, d) && now - (root._applied[name] || 0) > 3000) apply(name, d)
        }
    }

    function parse(json) {
        const list = JSON.parse(json).map(m => {
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
        }
    }

    Component.onCompleted: refresh()
}
