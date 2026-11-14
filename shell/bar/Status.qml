import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.widgets

// Bagian kanan bar: CPU, RAM, jaringan, volume, baterai. Klik = buka dashboard (klik WiFi = daftar WiFi).
Row {
    id: root
    spacing: Theme.ui(18)

    readonly property alias net: net

    // "Tetap menyala" aktif: kunci otomatis ditahan
    Txt { visible: Idle.caffeine; mono: true; font.pixelSize: Theme.ui(16); color: Theme.accent; text: Icons.coffee }
    Txt { mono: true; font.pixelSize: Theme.ui(13); color: Theme.muted; text: "CPU " + Math.round(SysStats.cpu * 100) + "%" }
    Txt { mono: true; font.pixelSize: Theme.ui(13); color: Theme.muted; text: "RAM " + SysStats.memUsed.toFixed(1).replace(".", ",") + "G" }

    Row {
        id: net
        spacing: 6
        Txt { mono: true; font.pixelSize: Theme.ui(17); color: Theme.accent2; text: Net.wired ? Icons.ethernet : Net.wifiNetwork ? Icons.wifi : Icons.wifiOff }
        Txt { text: Net.label; elide: Text.ElideRight; font.pixelSize: Theme.ui(Theme.fontSize); width: Math.min(implicitWidth, 140) }
    }

    Row {
        spacing: 6
        Txt { mono: true; font.pixelSize: Theme.ui(17); color: Theme.accent2; text: Audio.muted ? Icons.volumeMute : Audio.current?.kind === "headphones" ? Icons.headphones : Audio.current?.kind === "hdmi" ? Icons.monitor : Icons.volume }
        Txt { mono: true; font.pixelSize: Theme.ui(13); text: Audio.muted ? "bisu" : Math.round(Audio.volume * 100) }
    }

    Row {
        spacing: 6
        visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery
        readonly property real pct: UPower.displayDevice ? UPower.displayDevice.percentage : 0
        Txt {
            mono: true; font.pixelSize: Theme.ui(17)
            text: UPower.onBattery ? Icons.battery : Icons.batteryCharging
            color: parent.pct < 0.15 && UPower.onBattery ? Theme.bad : Theme.good
        }
        Txt { mono: true; font.pixelSize: Theme.ui(13); text: Math.round(parent.pct * 100) + "%" }
    }
}
