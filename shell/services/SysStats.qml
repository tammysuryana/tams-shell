pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Pemakaian CPU & RAM, dibaca langsung dari /proc tiap 5 detik (hemat CPU saat idle).
Singleton {
    id: root

    property real cpu: 0          // 0..1
    property real memUsed: 0      // GiB
    property real memTotal: 0     // GiB
    readonly property real mem: memTotal > 0 ? memUsed / memTotal : 0

    property var _prev: null

    FileView { id: stat; path: "/proc/stat" }
    FileView { id: meminfo; path: "/proc/meminfo" }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            stat.reload()
            meminfo.reload()
            root.readCpu(stat.text())
            root.readMem(meminfo.text())
        }
    }

    function readCpu(t) {
        const line = t.split("\n")[0]
        if (!line.startsWith("cpu ")) return
        const v = line.trim().split(/\s+/).slice(1).map(Number)
        const idle = v[3] + (v[4] || 0)
        const total = v.reduce((a, b) => a + b, 0)
        if (root._prev) {
            const dt = total - root._prev.total
            const di = idle - root._prev.idle
            if (dt > 0) root.cpu = Math.max(0, Math.min(1, 1 - di / dt))
        }
        root._prev = { total: total, idle: idle }
    }

    function readMem(t) {
        const get = k => {
            const m = t.match(new RegExp("^" + k + ":\\s+(\\d+)", "m"))
            return m ? Number(m[1]) / 1048576 : 0
        }
        root.memTotal = get("MemTotal")
        root.memUsed = root.memTotal - get("MemAvailable")
    }
}
