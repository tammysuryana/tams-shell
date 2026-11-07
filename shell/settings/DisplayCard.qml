import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Satu layar di Pengaturan. Layar tambahan: klik kotak di kiri/kanan/atas/bawah layar utama untuk
// memindahkannya, atau pilih Cermin / Mati. Semua layar: resolusi dan skala (dengan hitung mundur
// untuk kembali sendiri, kalau layar jadi tidak tampil).
Rectangle {
    id: root

    required property var m
    readonly property var main: Displays.main
    readonly property bool isMain: main !== null && main.name === m.name
    readonly property string place: Displays.placeOf(m)
    readonly property var cfg: Displays.conf(m.name)
    readonly property bool waiting: Displays.revert !== null && Displays.revert.name === m.name
    property bool modesOpen: false

    function short(x) { return x.internal ? "Laptop" : x.name.split("-")[0] }

    implicitHeight: col.implicitHeight + 24
    radius: 16
    color: Theme.surface

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Txt { mono: true; font.pixelSize: 20; color: root.m.disabled ? Theme.muted : Theme.accent; text: root.m.internal ? Icons.laptop : Icons.monitor }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Txt { Layout.fillWidth: true; elide: Text.ElideRight; text: root.m.label }
                Txt {
                    Layout.fillWidth: true; elide: Text.ElideRight; font.pixelSize: 11; color: Theme.muted
                    text: root.m.name + (root.isMain ? " · layar utama" : "")
                        + (root.m.disabled ? " · mati" : " · " + root.m.width + " × " + root.m.height + (root.m.scale !== 1 ? " · " + Math.round(root.m.scale * 100) + "%" : ""))
                }
            }
        }

        // Peta posisi terhadap layar utama
        Item {
            id: map
            visible: !root.isMain && root.main !== null
            Layout.fillWidth: true
            implicitHeight: 3 * sh + 2 * gap
            readonly property int sw: 86
            readonly property int sh: 48
            readonly property int gap: 6
            readonly property real cx: width / 2

            Rectangle {
                x: map.cx - map.sw / 2; y: map.sh + map.gap
                width: map.sw; height: map.sh; radius: 8
                color: Theme.surface2
                Txt {
                    anchors.centerIn: parent
                    font.pixelSize: 12
                    text: root.main ? root.short(root.main) + (root.place === "mirror" ? " = " + root.short(root.m) : "") : ""
                }
            }
            Slot { pos: "left"; label: "Kiri"; x: map.cx - map.sw / 2 - map.gap - map.sw; y: map.sh + map.gap }
            Slot { pos: "right"; label: "Kanan"; x: map.cx + map.sw / 2 + map.gap; y: map.sh + map.gap }
            Slot { pos: "up"; label: "Atas"; x: map.cx - map.sw / 2; y: 0 }
            Slot { pos: "down"; label: "Bawah"; x: map.cx - map.sw / 2; y: 2 * (map.sh + map.gap) }
        }

        RowLayout {
            visible: map.visible
            Layout.fillWidth: true
            spacing: 6
            Btn { Layout.fillWidth: true; bg: Theme.frame; label: "Cermin"; active: root.place === "mirror"; onClicked: Displays.set(root.m.name, { position: "mirror" }) }
            Btn { Layout.fillWidth: true; bg: Theme.frame; label: "Matikan"; active: root.place === "off"; onClicked: Displays.set(root.m.name, { position: "off" }) }
        }

        // Resolusi
        ExpandSwitch {
            visible: !root.m.disabled && root.m.modes.length > 0
            Layout.fillWidth: true
            switchable: false
            label: "Resolusi  ·  " + root.m.width + " × " + root.m.height
            expanded: root.modesOpen
            onExpandClicked: root.modesOpen = !root.modesOpen
        }
        ColumnLayout {
            visible: root.modesOpen && !root.m.disabled
            Layout.fillWidth: true
            spacing: 2
            Repeater {
                model: [{ v: "preferred", t: "Bawaan layar", w: 0, h: 0 }].concat(root.m.modes)
                Rectangle {
                    required property var modelData
                    readonly property bool on: modelData.v === "preferred" ? root.cfg.mode === "preferred"
                        : root.cfg.mode !== "preferred" && modelData.w === root.m.width && modelData.h === root.m.height
                    Layout.fillWidth: true
                    implicitHeight: 32
                    radius: 10
                    color: on ? Theme.accent : rowMouse.containsMouse ? Theme.surface2 : "transparent"
                    Txt { anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter } font.pixelSize: 13; text: parent.modelData.t; color: parent.on ? Theme.frame : Theme.text }
                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { root.modesOpen = false; Displays.set(root.m.name, { mode: parent.modelData.v }, true) }
                    }
                }
            }
        }

        // Skala
        Txt { visible: !root.m.disabled; text: "Skala"; font.pixelSize: 13; color: Theme.muted }
        RowLayout {
            visible: !root.m.disabled
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: [{ v: "auto", t: "Auto" }, { v: 1, t: "100%" }, { v: 1.25, t: "125%" }, { v: 1.5, t: "150%" }, { v: 2, t: "200%" }]
                Btn {
                    required property var modelData
                    Layout.fillWidth: true
                    pad: 4
                    bg: Theme.frame
                    label: modelData.t
                    active: String(root.cfg.scale) === String(modelData.v)
                    onClicked: Displays.set(root.m.name, { scale: modelData.v }, true)
                }
            }
        }

        // Konfirmasi setelah ganti resolusi/skala
        Rectangle {
            visible: root.waiting
            Layout.fillWidth: true
            implicitHeight: confirmRow.implicitHeight + 16
            radius: 12
            color: Theme.surface2
            RowLayout {
                id: confirmRow
                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
                spacing: 6
                Txt {
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    font.pixelSize: 12
                    text: "Tampilan sudah benar? Kembali sendiri dalam " + (root.waiting ? Displays.revert.secs : 0) + " detik"
                }
                SmallBtn { label: "Pertahankan"; onClicked: Displays.keep() }
                SmallBtn { label: "Kembalikan"; onClicked: Displays.undo() }
            }
        }
    }

    component Slot: Rectangle {
        id: slot
        property string pos
        property string label
        readonly property bool on: root.place === pos
        width: map.sw; height: map.sh; radius: 8
        color: on ? Theme.accent : slotMouse.containsMouse ? Theme.surface2 : "transparent"
        border.width: on ? 0 : 1
        border.color: Theme.line
        Txt {
            anchors.centerIn: parent
            font.pixelSize: 12
            text: slot.on ? root.short(root.m) : slot.label
            color: slot.on ? Theme.frame : Theme.muted
        }
        MouseArea {
            id: slotMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Displays.set(root.m.name, { position: slot.pos })
        }
    }
}
