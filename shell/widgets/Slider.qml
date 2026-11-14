import QtQuick
import qs.config

// Slider tipis dengan kenop bulat. value 0..1, kirim moved(v) saat digeser/diklik.
Item {
    id: root

    property string icon: ""
    property real value: 0
    property color fill: Theme.accent2
    property string display: Math.round(value * 100)   // angka di kanan
    signal moved(real v)

    implicitHeight: 30
    implicitWidth: 240

    Txt { id: ic; anchors.verticalCenter: parent.verticalCenter; text: root.icon; mono: true; font.pixelSize: 18; color: Theme.muted; width: root.icon !== "" ? 26 : 0 }
    Txt { id: num; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; mono: true; font.pixelSize: 12; color: Theme.muted; text: root.display; width: 30; horizontalAlignment: Text.AlignRight }

    Item {
        id: area
        anchors.left: ic.right
        anchors.right: num.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        height: 20

        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Theme.surface2 }
        // kenop selalu di dalam jalur: pada 0 menempel kiri, pada 1 menempel kanan (bukan setengah keluar)
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 8 + (parent.width - 16) * Math.min(1, root.value); height: 6; radius: 3; color: root.fill }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: (parent.width - 16) * Math.min(1, Math.max(0, root.value))
            width: 16; height: 16; radius: 8
            color: Theme.text
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function apply(mx) { root.moved(Math.max(0, Math.min(1, (mx - 8) / (width - 16)))) }
            onPressed: e => apply(e.x)
            onPositionChanged: e => { if (pressed) apply(e.x) }
            onWheel: e => root.moved(Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }
}
