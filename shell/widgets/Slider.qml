import QtQuick
import qs.config

// Slider tipis dengan kenop bulat. value 0..1, kirim moved(v) saat digeser/diklik.
Item {
    id: root

    property string icon: ""
    property real value: 0
    property color fill: Theme.accent2
    signal moved(real v)

    implicitHeight: 30
    implicitWidth: 240

    Txt { id: ic; anchors.verticalCenter: parent.verticalCenter; text: root.icon; mono: true; font.pixelSize: 18; color: Theme.muted; width: 26 }
    Txt { id: num; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; mono: true; font.pixelSize: 12; color: Theme.muted; text: Math.round(root.value * 100); width: 30; horizontalAlignment: Text.AlignRight }

    Item {
        id: area
        anchors.left: ic.right
        anchors.right: num.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        height: 20

        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: Theme.surface2 }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * Math.min(1, root.value); height: 6; radius: 3; color: root.fill }
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            x: parent.width * Math.min(1, root.value) - 8
            width: 16; height: 16; radius: 8
            color: Theme.text
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function apply(mx) { root.moved(Math.max(0, Math.min(1, mx / width))) }
            onPressed: e => apply(e.x)
            onPositionChanged: e => { if (pressed) apply(e.x) }
            onWheel: e => root.moved(Math.max(0, Math.min(1, root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }
}
