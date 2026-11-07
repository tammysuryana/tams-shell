import QtQuick
import Quickshell
import Quickshell.Wayland

// Pemantau idle untuk Idle. Harus dibuat langsung di shell.qml, bukan di dalam singleton:
// IdleMonitor baru aktif setelah reload selesai, dan singleton yang dibuat belakangan melewatkannya.
Scope {
    Watch { secs: Brightness.available ? Settings.idleDim : 0; onIdle: v => Idle.dim(v) }
    Watch { secs: Settings.idleLock; onIdle: v => { if (v) Power.lock() } }
    Watch { secs: Settings.idleScreenOff; onIdle: v => Idle.dpms(!v) }
    Watch { secs: Settings.idleSuspend; onIdle: v => { if (v) Quickshell.execDetached(["systemctl", "suspend"]) } }

    // IdleMonitor tidak ikut berubah kalau timeout diganti selagi menyala, jadi tiap ganti waktu:
    // matikan, pasang waktu baru, lalu nyalakan lagi.
    component Watch: IdleMonitor {
        id: w
        property int secs: 0
        signal idle(bool v)
        enabled: false
        onIsIdleChanged: w.idle(isIdle)
        onSecsChanged: restart()
        Component.onCompleted: restart()
        function restart() {
            w.enabled = false
            if (w.secs <= 0) return
            w.timeout = w.secs
            Qt.callLater(() => w.enabled = w.secs > 0)
        }
    }
}
