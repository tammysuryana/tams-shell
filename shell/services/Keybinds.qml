pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Daftar pintasan keyboard yang sedang aktif di Hyprland (hyprctl binds), dikelompokkan dan diberi
// keterangan. Keterangan diambil dari bind itu sendiri (description), kalau tidak ada ditebak dari
// dispatcher dan tombolnya. Pintasan yang mirip digabung (mis. Super + 1 … 0).
// Gesture touchpad dibaca dari file config Hyprland (hyprctl tidak punya daftarnya), ditambah
// pengaturan touchpad yang sedang aktif (scroll natural, klik & ketuk beberapa jari).
Singleton {
    id: root

    // [{ title, rows: [{ mods: ["Super"], keys: ["1", "0"], range: true, text }] }]
    readonly property var sections: {
        const out = root._binds.slice()
        if (root._touch.length) {
            const i = out.findIndex(s => s.title === "Tombol media")
            out.splice(i < 0 ? out.length : i, 0, { title: "Touchpad", rows: root._touch })
        }
        return out
    }
    property var _binds: []
    property var _touch: []

    function refresh() { proc.running = true; gestProc.running = true }

    readonly property var modBits: [[64, "Super"], [4, "Ctrl"], [8, "Alt"], [1, "Shift"]]

    readonly property var keyNames: ({
        SUPER_L: "Super", SUPER_R: "Super", Page_Up: "PgUp", Page_Down: "PgDn", Prior: "PgUp", Next: "PgDn",
        Semicolon: ";", Apostrophe: "'", BracketLeft: "[", BracketRight: "]", Minus: "−", Equal: "=", Period: ".",
        Backslash: "\\", Delete: "Del", "mouse:274": "Klik tengah", "mouse:275": "Tombol samping",
        "mouse:276": "Tombol samping 2",
        Space: "Space", space: "Space", Escape: "Esc", Return: "Enter", Tab: "Tab", slash: "/", Print: "PrtSc",
        left: "←", right: "→", up: "↑", down: "↓", Left: "←", Right: "→", Up: "↑", Down: "↓",
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
        keys: "Daftar pintasan ini", launcherTap: "Launcher: cari aplikasi", lock: "Kunci layar",
        wallpaper: "Pilih wallpaper", theme: "Ganti gelap / terang", caffeine: "Tetap menyala",
        restart: "Mulai ulang shell",
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
        // Keterangan "Bagian: teks" masuk ke bagian itu
        const part = /^([^:]{2,20}):\s*(.+)$/.exec(desc)
        if (part) return [part[1], part[2]]
        if (desc) return ["Lainnya", desc]
        if (disp === "global") {
            const name = readable ? arg.replace(/^tams:/, "") : ""
            return ["tams", root.tamsText[name] || (name ? "Global: " + name : "Fungsi tams-shell")]
        }
        if (key === "XF86AudioMute" && mods.indexOf("Alt") >= 0) return ["Tombol media", root.mediaText.XF86AudioMicMute]
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
        const order = ["tams", "Jendela", "Workspace", "Aplikasi", "Utilitas", "Media", "Tombol media", "Sesi", "Layar", "Lainnya"]
        const titles = { tams: "tams-shell" }
        const groups = {}
        const binds = JSON.parse(json)
        // Config pengguna sudah memberi keterangan di banyak bind (gaya end4): bind tanpa keterangan
        // dianggap pembantu tersembunyi, kecuali tombol media. Kalau tidak, semua bind ditampilkan.
        const strict = binds.filter(b => b.has_description && !/^tams-shell:/.test(b.description)).length >= 10
        for (const b of binds) {
            if (strict && !b.has_description && !b.key.startsWith("XF86")) continue
            // non_consuming = bind pembantu yang tak terlihat (mis. pembatal Super ditekan sendiri)
            if (b.submap || b.catch_all || b.non_consuming) continue
            let mods = root.modBits.filter(m => b.modmask & m[0]).map(m => m[1])
            const disp = (/^HL\.Dispatcher\((.+)\)$/.exec(b.dispatcher) || [null, b.dispatcher])[1]
            const key = b.key
            // Super ditekan sendiri: tampil sebagai "Super" saja
            if (/^SUPER_[LR]$/.test(key)) mods = []
            let [sec, text] = describe(b, disp, key, mods.join("+"))
            text = text.charAt(0).toUpperCase() + text.slice(1)
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
        root._binds = out
    }

    readonly property var gestureDirs: ({
        horizontal: "← →", vertical: "↑ ↓", left: "←", right: "→", up: "↑", down: "↓",
        swipe: "geser", pinch: "cubit", pinchin: "cubit masuk", pinchout: "cubit keluar"
    })
    readonly property var gestureText: ({
        workspace: "Pindah workspace", move: "Pindahkan jendela", resize: "Ubah ukuran jendela",
        float: "Jendela melayang / tertata", fullscreen: "Layar penuh", close: "Tutup jendela",
        special: "Workspace khusus", cursorZoom: "Perbesar sekitar kursor"
    })

    // teks = isi file config Hyprland, lalu "@@TOUCHPAD@@", lalu keluaran hyprctl getoption
    function parseGestures(text) {
        const [cfg, opts] = text.split("@@TOUCHPAD@@")
        const rows = []
        const add = (fingers, dir, mods, action, fn) => {
            let t = root.gestureText[action]
            if (!t && fn) {
                const g = /global\(\s*"(?:tams:)?([^"]+)"/.exec(fn)
                t = g ? (root.tamsText[g[1]] || g[1]) : "Fungsi khusus"
            }
            // jumlah jari ditulis seperti tombol pengubah (tanpa "/"), arahnya sebagai tombol
            const m = mods ? mods.split(/[\s+]+/).filter(x => x).map(x => x[0] + x.slice(1).toLowerCase()) : []
            rows.push({ mods: m.concat([fingers + " jari"]), keys: [root.gestureDirs[dir] || dir], text: t || action, range: false })
        }
        if (Hyprland.usingLua) {
            const src = cfg.split("\n").map(l => l.replace(/^\s*--.*$/, "")).join("\n")
            const re = /hl\.gesture\(\s*\{([\s\S]*?)\}\s*\)/g
            let m
            while ((m = re.exec(src)) !== null) {
                const body = m[1]
                const get = k => { const r = new RegExp(k + "\\s*=\\s*\"([^\"]*)\"").exec(body); return r ? r[1] : "" }
                const f = /fingers\s*=\s*(\d+)/.exec(body)
                if (!f) continue
                add(f[1], get("direction"), get("mods"), get("action"), /action\s*=\s*function/.test(body) ? body : "")
            }
        } else {
            for (const line of cfg.split("\n")) {
                const g = /^\s*gesture\s*=\s*(.+)$/.exec(line.replace(/#.*$/, ""))
                if (!g) continue
                const parts = g[1].split(",").map(x => x.trim())
                let mods = ""
                const rest = parts.slice(2).filter(x => {
                    if (x.startsWith("mod:")) { mods = x.slice(4).trim(); return false }
                    return !x.startsWith("scale:")
                })
                add(parts[0], parts[1], mods, rest[0] || "", rest[0] === "dispatcher" ? rest.join(",") : "")
            }
        }
        // Pengaturan touchpad yang sedang dipakai
        const o = {}
        for (const j of (opts || "").split("\n")) {
            try { const v = JSON.parse(j); o[v.option.split(":").pop()] = v.bool ?? !!v.int } catch (e) {}
        }
        if (o.natural_scroll !== undefined)
            rows.unshift({ mods: ["2 jari"], keys: ["geser"], text: o.natural_scroll ? "Scroll (natural)" : "Scroll", range: false })
        if (o.clickfinger_behavior) {
            rows.push({ mods: [], keys: ["Klik 2 jari"], text: "Klik kanan", range: false })
            rows.push({ mods: [], keys: ["Klik 3 jari"], text: "Klik tengah", range: false })
        }
        if (o["tap-to-click"]) rows.push({ mods: [], keys: ["Ketuk 1 / 2 / 3 jari"], text: "Klik / kanan / tengah", range: false })
        root._touch = rows
    }

    Process {
        id: gestProc
        command: ["sh", "-c", 'd="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"; '
            + 'find "$d" -maxdepth 3 -type f -name "*.$1" -exec cat {} + 2>/dev/null; echo "@@TOUCHPAD@@"; '
            + 'for o in natural_scroll clickfinger_behavior tap-to-click; do hyprctl getoption "input:touchpad:$o" -j | tr -d "\\n"; echo; done',
            "sh", Hyprland.usingLua ? "lua" : "conf"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.parseGestures(text) } catch (e) { console.warn("Keybinds gesture: " + e) } }
        }
    }

    Process {
        id: proc
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: { try { root.parse(text) } catch (e) { console.warn("Keybinds: " + e) } }
        }
    }
}
