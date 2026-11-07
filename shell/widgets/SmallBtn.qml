import QtQuick
import qs.config

// Tombol teks kecil (aksi di baris daftar: Putus, Lupakan, Sambung, ...).
Rectangle {
    id: b

    property string label: ""
    property alias containsMouse: m.containsMouse
    signal clicked()

    implicitWidth: t.implicitWidth + 16
    implicitHeight: 26
    radius: 8
    color: m.containsMouse ? Theme.accent : Theme.line

    Txt { id: t; anchors.centerIn: parent; text: b.label; font.pixelSize: 12; color: m.containsMouse ? Theme.frame : Theme.text }
    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.clicked() }
}
