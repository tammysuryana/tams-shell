pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Daftar pintasan keyboard yang sedang aktif di Hyprland (hyprctl binds), dikelompokkan dan diberi
// keterangan. Keterangan diambil dari bind itu sendiri (description), kalau tidak ada ditebak dari
// dispatcher dan tombolnya. Pintasan yang mirip digabung (mis. Super + 1 … 0).
Singleton {
    id: root

    // [{ title, rows: [{ mods: ["Super"], keys: ["1", "0"], range: true, text }] }]
    property var sections: []

    function refresh() { proc.running = true }

    readonly property var modBits: [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]]

    readonly property var keyNames: ({
        Space: "Space", space: "Space", Escape: "Esc", Return: "Enter", Tab: "Tab", slash: "/", Print: "PrtSc",
        left: "←", right: "→", up: "↑", down: "↓",
        mouse_down: "Roda ↓", mouse_up: "Roda ↑", "mouse:272": "Klik kiri", "mouse:273": "Klik kanan",
        XF86AudioRaiseVolume: "Vol +", XF86AudioLowerVolume: "Vol −", XF86AudioMute: "Bisu", XF86AudioMicMute: "Mic",
        XF86MonBrightnessUp: "Terang +", XF86MonBrightnessDown: "Terang −",
        XF86AudioNext: "⏭", XF86AudioPrev: "⏮", XF86AudioPlay: "⏯", XF86AudioPause: "⏸"
    })

    // Pasangan naik/turun diberi keterangan sama supaya digabung jadi satu baris
    readonly property var mediaText: ({
        XF86AudioRaiseVolume: "Volume naik / turun", XF86AudioLowerVolume: "Volume naik / turun", XF86AudioMute: "Suara bisu / nyala",
        XF86AudioMicMute: "Mikrofon bisu / nyala", XF86MonBrightnessUp: "Kecerahan layar", XF86MonBrightnessDown: "Kecerahan layar",
        XF86AudioPrev: "Lagu sebelumnya / berikutnya", XF86AudioNext: "Lagu sebelumnya / berikutnya",
        XF86AudioPlay: "Putar / jeda", XF86AudioPause: "Putar / jeda"
    })

    // Fungsi tams-shell (Hyprland global tams:<nama>)
    readonly property var tamsText: ({
        launcher: "Launcher: cari aplikasi", dashboard: "Dashboard", settings: "Pengaturan", pengaturan: "Pengaturan",
        keys: "Daftar pintasan ini",
        screenshotArea: "Screenshot area / jendela", screenshotScreen: "Screenshot layar ini", screenshotAll: "Screenshot semua layar"
    })

    // Bind bawaan config Hyprland yang perintahnya tidak terbaca (config Lua hanya memberi nomor)
    readonly property var defaultExec: ({ Q: "Buka terminal", E: "Buka file manager", M: "Keluar dari Hyprland", R: "Menu aplikasi" })

    function describe(b, disp, key, mods) {
        const arg = String(b.arg)
        const readable = !/^\d+$/.test(arg)
        const desc = b.has_description ? b.description : ""
        const tams = /^tams-shell:\s*(.+)$/.exec(desc)
        const dirs = { left: "kiri", right: "kanan", up: "atas", down: "bawah", l: "kiri", r: "kanan", u: "atas", d: "bawah" }
        const digit = /^\d$/.test(key)
        const ws = digit ? (key === "0" ? "10" : key) : ""

        if (tams) return ["tams", root.tamsText[tams[1]] || tams[1]]
        if (desc) return ["Lainnya", desc]
        if (disp === "global") {
            const name = readable ? arg.replace(/^tams:/, "") : ""
            return ["tams", root.tamsText[name] || (name ? "Global: " + name : "Fungsi tams-shell")]
        }
        if (root.mediaText[key]) return ["Tombol media", root.mediaText[key]]
        switch (disp) {
        case "exec": case "exec_cmd":
            if (readable) return ["Aplikasi", "Jalankan " + (arg.length > 34 ? arg.slice(0, 33) + "…" : arg)]
            if (mods === "Super" && root.defaultExec[key]) return ["Aplikasi", root.defaultExec[key]]
            return ["Aplikasi", "Jalankan perintah"]
        case "close": case "killactive": case "forcekillactive": return ["Jendela", "Tutup jendela"]
        case "float": case "togglefloating": return ["Jendela", "Jendela melayang / tertata"]
        case "fullscreen": return ["Jendela", "Layar penuh"]
        case "pseudo": return ["Jendela", "Mode pseudo (dwindle)"]
        case "layout": case "togglesplit": return ["Jendela", "Ganti arah belah jendela"]
        case "drag": case "movewindow": if (b.mouse) return ["Jendela", "Seret untuk memindah jendela"]; break
        case "resize": case "resizewindow": if (b.mouse) return ["Jendela", "Seret untuk mengubah ukuran"]; break
        case "toggle_special": case "togglespecialworkspace": return ["Workspace", "Buka / tutup workspace khusus"]
        case "exit": return ["Aplikasi", "Keluar dari Hyprland"]
        }
        if (disp === "focus" || disp === "movefocus" || disp === "workspace") {
            if (digit) return ["Workspace", "Ke workspace 1 – 10"]
            if (key === "mouse_down" || key === "mouse_up") return ["Workspace", "Ganti workspace"]
            if (dirs[key] || dirs[arg]) return ["Jendela", "Pindah fokus antar jendela"]
            if (disp === "workspace" && readable) return ["Workspace", "Ke workspace " + arg]
        }
        if (disp === "move" || disp === "movetoworkspace" || disp === "movetoworkspacesilent" || disp === "movewindow") {
            if (digit) return ["Workspace", "Pindahkan jendela ke workspace 1 – 10"]
            if (key === "S") return ["Workspace", "Pindahkan jendela ke workspace khusus"]
            if (dirs[key]) return ["Jendela", "Geser jendela"]
        }
        return ["Lainnya", disp + (readable && arg ? " " + arg : "")]
    }

    function parse(json) {
        const order = ["tams", "Jendela", "Workspace", "Aplikasi", "Tombol media", "Lainnya"]
        const titles = { tams: "tams-shell" }
        const groups = {}
        for (const b of JSON.parse(json)) {
            if (b.submap || b.catch_all) continue
            const mods = root.modBits.filter(m => b.modmask & m[0]).map(m => m[1])
            const disp = (/^HL\.Dispatcher\((.+)\)$/.exec(b.dispatcher) || [null, b.dispatcher])[1]
            const key = b.key
            const [sec, text] = describe(b, disp, key, mods.join("+"))
            const label = root.keyNames[key] ?? (key.length === 1 ? key.toUpperCase() : key)
            const list = groups[sec] ?? (groups[sec] = [])
            // Gabung dengan baris yang modifier & keterangannya sama
            const same = list.find(r => r.text === text && r.mods.join("+") === mods.join("+"))
            if (same) same.keys.push(label)
            else list.push({ mods: mods, keys: [label], text: text })
        }
        const out = []
        for (const sec of order) {
            if (!groups[sec]) continue
            for (const r of groups[sec]) r.range = r.keys.length > 2 && r.keys.every(k => /^\d$/.test(k))
            out.push({ title: titles[sec] || sec, rows: groups[sec] })
        }
        root.sections = out
    }

    Process {
        id: proc
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.parse(text) } catch (e) { console.warn("Keybinds: " + e) } }
        }
    }
}
