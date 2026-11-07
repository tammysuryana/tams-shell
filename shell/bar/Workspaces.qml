import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.services
import qs.widgets

// Workspace 1..N: aksen = aktif, terang = ada jendela, redup = kosong. Klik untuk pindah.
// Gaya (Pengaturan → Bingkai): angka 1 2 3, titik, romawi I II III, atau kanji 一 二 三.
Row {
    id: root

    property var monitor: null
    property int count: 5
    readonly property string style: Settings.workspaceStyle
    spacing: style === "dot" ? 0 : 4

    readonly property int activeId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : 1
    readonly property int shown: {
        let max = root.count
        const ws = Hyprland.workspaces.values
        for (let i = 0; i < ws.length; i++) if (ws[i].id > max && ws[i].id < 100) max = ws[i].id
        return max
    }

    function occupied(id) {
        const ws = Hyprland.workspaces.values
        for (let i = 0; i < ws.length; i++) if (ws[i].id === id) return ws[i].toplevels.values.length > 0
        return false
    }

    function roman(n) {
        const r = [[10, "X"], [9, "IX"], [5, "V"], [4, "IV"], [1, "I"]]
        let out = ""
        for (const [v, s] of r) while (n >= v) { out += s; n -= v }
        return out
    }
    function label(id) {
        if (root.style === "roman") return roman(id)
        if (root.style === "kanji" && id <= 10) return "一二三四五六七八九十"[id - 1]
        return String(id)
    }

    Repeater {
        model: root.shown
        Item {
            id: ws
            required property int index
            readonly property int wsId: index + 1
            readonly property bool active: wsId === root.activeId
            readonly property bool used: root.occupied(wsId)
            readonly property bool dot: root.style === "dot"
            width: dot ? (active ? 30 : 16) : Math.max(26, txt.implicitWidth + 12)
            height: 26
            Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            // Gaya teks: kotak bulat di belakang angka/huruf
            Rectangle {
                visible: !ws.dot
                anchors.fill: parent
                radius: 8
                color: ws.active ? Theme.accent : mouse.containsMouse ? Theme.surface2 : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            Txt {
                id: txt
                visible: !ws.dot
                anchors.centerIn: parent
                text: root.label(ws.wsId)
                mono: root.style !== "kanji"
                font.pixelSize: 13
                font.weight: ws.active ? Font.Bold : Font.Normal
                color: ws.active ? Theme.frame : ws.used ? Theme.text : Theme.muted
            }

            // Gaya titik: aktif memanjang, ada jendela = titik penuh, kosong = cincin
            Rectangle {
                visible: ws.dot
                anchors.centerIn: parent
                width: ws.active ? 20 : 8
                height: 8
                radius: 4
                color: ws.active ? Theme.accent : ws.used ? Theme.text : "transparent"
                border.width: ws.active || ws.used ? 0 : 1.5
                border.color: mouse.containsMouse ? Theme.text : Theme.muted
                Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ workspace = ${ws.wsId} })` : `workspace ${ws.wsId}`)
            }
        }
    }
}
