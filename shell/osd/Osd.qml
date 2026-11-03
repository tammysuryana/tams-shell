import QtQuick
import qs.config
import qs.services
import qs.widgets

// Indikator volume / kecerahan yang keluar dari sisi kanan bingkai selama 1,5 detik.
Item {
    id: root

    readonly property int r: Theme.panelRadius
    property bool show: false
    property string kind: "volume"
    readonly property real value: kind === "volume" ? Audio.volume : Brightness.value

    width: show ? 64 : 0
    height: 250 + r * 2
    clip: true
    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    function pop(k) { root.kind = k; root.show = true; hide.restart() }
    Timer { id: hide; interval: 1500; onTriggered: root.show = false }

    property bool _ready: false
    Timer { interval: 1500; running: true; onTriggered: root._ready = true }   // abaikan perubahan saat shell baru mulai
    Connections { target: Audio; function onChanged() { if (root._ready) root.pop("volume") } }
    Connections { target: Brightness; function onChanged() { if (root._ready) root.pop("brightness") } }

    // telinga atas & bawah, menempel bingkai kanan
    Corner { corner: "br"; x: root.width - root.r; y: 0; size: root.r }
    Corner { corner: "tr"; x: root.width - root.r; y: root.height - root.r; size: root.r }

    Rectangle {
        y: root.r
        width: 64
        height: 250
        color: Theme.frame
        radius: root.r
        Rectangle { anchors.right: parent.right; width: root.r; height: parent.height; color: Theme.frame }

        Column {
            anchors.centerIn: parent
            spacing: 12
            Item {
                width: 10; height: 170
                anchors.horizontalCenter: parent.horizontalCenter
                Rectangle { anchors.fill: parent; radius: 5; color: Theme.surface2 }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: parent.height * Math.min(1, root.value); radius: 5; color: root.kind === "volume" ? Theme.accent2 : Theme.accent }
            }
            Txt {
                anchors.horizontalCenter: parent.horizontalCenter
                mono: true; font.pixelSize: 20; color: Theme.muted
                text: root.kind === "volume" ? (Audio.muted ? Icons.volumeMute : Icons.volume) : Icons.brightness
            }
        }
    }
}
