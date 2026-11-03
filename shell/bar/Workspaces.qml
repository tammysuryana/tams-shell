import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config
import qs.widgets

// Nomor workspace 1..N: kuning = aktif, terang = ada jendela, redup = kosong. Klik untuk pindah.
Row {
    id: root

    property var monitor: null
    property int count: 5
    spacing: 4

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

    Repeater {
        model: root.shown
        Rectangle {
            required property int index
            readonly property int wsId: index + 1
            readonly property bool active: wsId === root.activeId
            width: 26; height: 26; radius: 8
            color: active ? Theme.accent : mouse.containsMouse ? Theme.surface2 : "transparent"
            Behavior on color { ColorAnimation { duration: 150 } }
            Txt {
                anchors.centerIn: parent
                text: parent.wsId
                mono: true
                font.pixelSize: 13
                font.weight: parent.active ? Font.Bold : Font.Normal
                color: parent.active ? Theme.frame : root.occupied(parent.wsId) ? Theme.text : Theme.muted
            }
            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ workspace = ${parent.wsId} })` : `workspace ${parent.wsId}`)
            }
        }
    }
}
