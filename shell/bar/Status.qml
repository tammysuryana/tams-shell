import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.config
import qs.services
import qs.widgets

// Bagian kanan bar: CPU, RAM, jaringan, volume, baterai. Klik = buka dashboard (klik WiFi = daftar WiFi).
// Statistik sistem (CPU/RAM) tampil halus sebagai ikon + angka (ambient, redup); status jaringan/
// suara/baterai memakai ikon berwarna. Angka pakai font proporsional; ikon & teks disejajarkan vertikal.
Row {
    id: root
    spacing: Theme.ui(16)

    readonly property alias net: net

    // "Tetap menyala" aktif: kunci otomatis ditahan
    Txt {
        visible: Idle.caffeine
        anchors.verticalCenter: parent.verticalCenter
        mono: true; font.pixelSize: Theme.ui(16); color: Theme.accent; text: Icons.coffee
    }

    // CPU & RAM: statistik ambient (ikon redup + angka)
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.ui(14)
        Row {
            spacing: Theme.ui(5)
            Txt { anchors.verticalCenter: parent.verticalCenter; mono: true; font.pixelSize: Theme.ui(14); color: Theme.muted; text: Icons.cpu }
            Txt { anchors.verticalCenter: parent.verticalCenter; font.pixelSize: Theme.ui(13); color: Theme.muted; text: Math.round(SysStats.cpu * 100) + "%" }
        }
        Row {
            spacing: Theme.ui(5)
            Txt { anchors.verticalCenter: parent.verticalCenter; mono: true; font.pixelSize: Theme.ui(14); color: Theme.muted; text: Icons.memory }
            Txt { anchors.verticalCenter: parent.verticalCenter; font.pixelSize: Theme.ui(13); color: Theme.muted; text: SysStats.memUsed.toFixed(1).replace(".", ",") + "G" }
        }
    }

    Row {
        id: net
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.ui(6)
        Txt { anchors.verticalCenter: parent.verticalCenter; mono: true; font.pixelSize: Theme.ui(17); color: Theme.accent2; text: Net.wired ? Icons.ethernet : Net.wifiNetwork ? Icons.wifi : Icons.wifiOff }
        Txt { anchors.verticalCenter: parent.verticalCenter; text: Net.label; elide: Text.ElideRight; color: Theme.text; font.pixelSize: Theme.ui(Theme.fontSize); width: Math.min(implicitWidth, Theme.ui(140)) }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.ui(6)
        Txt { anchors.verticalCenter: parent.verticalCenter; mono: true; font.pixelSize: Theme.ui(17); color: Theme.accent2; text: Audio.muted ? Icons.volumeMute : Audio.current?.kind === "headphones" ? Icons.headphones : Audio.current?.kind === "hdmi" ? Icons.monitor : Icons.volume }
        Txt { anchors.verticalCenter: parent.verticalCenter; font.pixelSize: Theme.ui(13); color: Theme.text; text: Audio.muted ? "bisu" : Math.round(Audio.volume * 100) }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.ui(6)
        visible: UPower.displayDevice && UPower.displayDevice.isLaptopBattery
        readonly property real pct: UPower.displayDevice ? UPower.displayDevice.percentage : 0
        Txt {
            anchors.verticalCenter: parent.verticalCenter
            mono: true; font.pixelSize: Theme.ui(17)
            text: UPower.onBattery ? Icons.battery : Icons.batteryCharging
            color: parent.pct < 0.15 && UPower.onBattery ? Theme.bad : Theme.good
        }
        Txt { anchors.verticalCenter: parent.verticalCenter; font.pixelSize: Theme.ui(13); color: Theme.text; text: Math.round(parent.pct * 100) + "%" }
    }
}
