pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Saat komputer ditinggal: redupkan layar → kunci → matikan layar → tidur, masing-masing setelah
// sekian detik tanpa sentuhan (0 = tidak dipakai; dipantau oleh IdleWatcher). Diatur di
// Pengaturan → Saat ditinggal.
// Aplikasi yang memutar video (penghambat idle) dan sakelar "Tetap menyala" menunda semuanya.
// Juga: kunci layar sebelum laptop tidur / ditutup (logind PrepareForSleep).
Singleton {
    id: root

    // Sakelar "Tetap menyala" di dashboard (tidak disimpan; mati lagi setelah shell dimulai ulang)
    property bool caffeine: false

    property real _brightness: -1   // kecerahan sebelum diredupkan
    property bool _sleeping: false  // sedang menuju tidur: penghambat dilepas

    function dpms(on) {
        const a = on ? "on" : "off"
        Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.dpms({ action = "${a}" })` : `dpms ${a}`)
    }

    // Dipanggil oleh IdleWatcher (pemantau idle-nya ada di sana, lihat catatan di file itu)
    function dim(idle) {
        if (idle) {
            root._brightness = Brightness.value
            Brightness.set(Math.max(0.05, Brightness.value * 0.3), true)
        } else if (root._brightness > 0) {
            Brightness.set(root._brightness, true)
            root._brightness = -1
        }
    }

    // Kunci sebelum tidur. Penghambat "delay" membuat logind menunggu (maks. beberapa detik) sampai
    // hyprlock sempat tampil, supaya isi layar tidak terlihat sekejap waktu laptop dibuka lagi.
    Process {
        id: delayLock
        running: Settings.lockOnSleep && !root._sleeping
        command: ["systemd-inhibit", "--what=sleep", "--mode=delay", "--who=tams-shell",
                  "--why=Kunci layar sebelum tidur", "sleep", "infinity"]
    }
    Process {
        running: Settings.lockOnSleep
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1"]
        stdout: SplitParser {
            onRead: line => {
                if (line.indexOf("PrepareForSleep (true") >= 0) {
                    Power.lock()
                    release.restart()
                } else if (line.indexOf("PrepareForSleep (false") >= 0) {
                    release.stop()
                    root._sleeping = false   // bangun: pasang penghambat lagi
                    root.dpms(true)
                }
            }
        }
    }
    // Lepas penghambat setelah layar kunci sempat muncul, supaya laptop benar-benar tidur
    Timer { id: release; interval: 1000; onTriggered: root._sleeping = true }
}
