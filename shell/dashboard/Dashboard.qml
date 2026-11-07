import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Bluetooth
import qs.config
import qs.services
import qs.widgets

// Dashboard yang tumbuh dari bingkai atas (klik jam). Lebar tetap, tinggi beranimasi dari 0.
Item {
    id: root

    property bool open: false
    readonly property int panelWidth: 1000
    readonly property int r: Theme.panelRadius

    width: panelWidth + r * 2
    height: open ? body.implicitHeight : 0
    visible: height > 0
    clip: true
    Behavior on height { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }

    // "Telinga" cekung kiri & kanan agar panel menyatu dengan bingkai
    Corner { corner: "tr"; size: Math.min(root.r, root.height); x: root.r - size; y: 0 }
    Corner { corner: "tl"; size: Math.min(root.r, root.height); x: root.r + root.panelWidth; y: 0 }

    Rectangle {
        id: body
        x: root.r
        width: root.panelWidth
        height: implicitHeight
        implicitHeight: grid.implicitHeight + 56
        readonly property int colW: (width - 56 - 56) / 3
        color: Theme.frame
        radius: root.r
        // sudut atas lurus (menyambung ke bingkai)
        Rectangle { width: parent.width; height: root.r; color: Theme.frame }

        GridLayout {
            id: grid
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 28 }
            columns: 3
            columnSpacing: 28

            // Kolom 1: jam, tanggal, media
            ColumnLayout {
                Layout.preferredWidth: body.colW
                Layout.maximumWidth: body.colW
                Layout.alignment: Qt.AlignTop
                spacing: 6
                Row {
                    Txt { mono: true; font.pixelSize: 64; font.weight: Font.Bold; text: Qt.formatTime(clock.date, "HH") }
                    Txt { mono: true; font.pixelSize: 64; font.weight: Font.Bold; text: ":"; color: Theme.accent }
                    Txt { mono: true; font.pixelSize: 64; font.weight: Font.Bold; text: Qt.formatTime(clock.date, "mm") }
                }
                Txt { color: Theme.muted; text: Qt.locale().toString(clock.date, "dddd, d MMMM yyyy") }
                Media { Layout.fillWidth: true; Layout.topMargin: 18 }
            }

            // Kolom 2: sistem
            ColumnLayout {
                Layout.preferredWidth: body.colW
                Layout.maximumWidth: body.colW
                Layout.alignment: Qt.AlignTop
                spacing: 0
                RowLayout {
                    Layout.fillWidth: true
                    Heading { text: "Sistem"; Layout.fillWidth: true }
                    Txt {
                        mono: true; font.pixelSize: 18; color: cogMouse.containsMouse ? Theme.accent : Theme.muted
                        text: Icons.cog
                        Layout.bottomMargin: 6
                        MouseArea { id: cogMouse; anchors { fill: parent; margins: -6 } hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Panels.toggleSettings() }
                    }
                }
                WifiPanel { Layout.fillWidth: true; active: root.open }
                Switch {
                    Layout.fillWidth: true
                    readonly property var a: Bluetooth.defaultAdapter
                    readonly property var dev: {
                        if (!a) return null
                        const d = a.devices.values
                        for (let i = 0; i < d.length; i++) if (d[i].connected) return d[i]
                        return null
                    }
                    visible: a !== null
                    label: "Bluetooth"; sub: dev ? dev.name : ""
                    checked: a ? a.enabled : false
                    onToggled: if (a) a.enabled = !a.enabled
                }
                Switch { Layout.fillWidth: true; label: "Jangan ganggu"; checked: Notifs.dnd; onToggled: Notifs.dnd = !Notifs.dnd }
                Switch { Layout.fillWidth: true; label: "Lampu malam"; checked: NightLight.on; onToggled: NightLight.toggle() }
                Slider { Layout.fillWidth: true; Layout.topMargin: 12; icon: Audio.muted ? Icons.volumeMute : Icons.volume; value: Audio.volume; onMoved: v => Audio.setVolume(v) }
                Slider { Layout.fillWidth: true; visible: Brightness.available; icon: Icons.brightness; value: Brightness.value; onMoved: v => Brightness.set(v) }
            }

            // Kolom 3: notifikasi + daya
            ColumnLayout {
                Layout.preferredWidth: body.colW
                Layout.maximumWidth: body.colW
                Layout.alignment: Qt.AlignTop
                spacing: 10
                RowLayout {
                    Layout.fillWidth: true
                    Heading { text: "Notifikasi · " + Notifs.list.length; Layout.fillWidth: true }
                    Txt { visible: Notifs.list.length > 0; text: "Hapus"; color: Theme.muted; font.pixelSize: 12
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.dismissAll() } }
                }
                Txt { visible: Notifs.list.length === 0; text: "Tidak ada notifikasi"; color: Theme.muted }
                Repeater {
                    model: Notifs.list.slice(0, 3)
                    NotifCard { required property var modelData; notif: modelData; Layout.fillWidth: true }
                }
                Heading { text: "Daya"; Layout.topMargin: 8 }
                GridLayout {
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8
                    Btn { label: "Kunci"; icon: Icons.lock; onClicked: { Panels.closeAll(); Power.lock() } }
                    Btn { label: "Keluar"; icon: Icons.logout; onClicked: Power.logout() }
                    Btn { label: "Ulang"; icon: Icons.restart; onClicked: Power.reboot() }
                    Btn { label: "Matikan"; icon: Icons.power; fg: Theme.bad; onClicked: Power.poweroff() }
                }
            }
        }
    }

    component Heading: Txt {
        font.pixelSize: 11
        font.letterSpacing: 2
        font.capitalization: Font.AllUppercase
        color: Theme.muted
        Layout.bottomMargin: 6
    }

    SystemClock { id: clock; precision: SystemClock.Seconds; enabled: root.open }
}
