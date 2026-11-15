import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.widgets

// Sisi kanan bar: ikon saja (jaringan, suara, baterai) — bersih & sekilas.
// Semua angka/detail (CPU, RAM, volume, nama WiFi, persen baterai) ada di Control Center
// yang terbuka saat bar kanan diklik. Ikon baterai menunjukkan level lewat bentuknya.
Row {
    id: root
    spacing: Theme.ui(15)

    // Ikon baterai sesuai level (tanpa angka): kosong .. penuh.
    function batteryGlyph(pct, charging) {
        if (charging) return Icons.batteryCharging
        const steps = [0xF008E, 0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E, 0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079]
        const i = Math.max(0, Math.min(10, Math.round(pct * 10)))
        return String.fromCodePoint(steps[i])
    }

    // "Tetap menyala" aktif
    Txt { visible: Idle.caffeine; anchors.verticalCenter: parent.verticalCenter; mono: true; font.pixelSize: Theme.ui(16); color: Theme.accent; text: Icons.coffee }

    // Jaringan
    Txt {
        anchors.verticalCenter: parent.verticalCenter
        mono: true; font.pixelSize: Theme.ui(17); color: Theme.accent2
        text: Net.wired ? Icons.ethernet : Net.wifiNetwork ? Icons.wifi : Icons.wifiOff
    }

    // Suara
    Txt {
        anchors.verticalCenter: parent.verticalCenter
        mono: true; font.pixelSize: Theme.ui(17); color: Audio.muted ? Theme.muted : Theme.accent2
        text: Audio.muted ? Icons.volumeMute : Audio.current?.kind === "headphones" ? Icons.headphones : Audio.current?.kind === "hdmi" ? Icons.monitor : Icons.volume
    }

    // Baterai (level lewat bentuk ikon; merah saat lemah, hijau saat mengisi)
    Txt {
        visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery
        anchors.verticalCenter: parent.verticalCenter
        mono: true; font.pixelSize: Theme.ui(18)
        readonly property real pct: UPower.displayDevice ? UPower.displayDevice.percentage : 0
        text: root.batteryGlyph(pct, !UPower.onBattery)
        color: !UPower.onBattery ? Theme.good : (pct < 0.15 ? Theme.bad : Theme.text)
    }
}
