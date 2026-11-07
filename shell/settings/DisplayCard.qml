import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Satu layar di Pengaturan.
// Layar tambahan: peta dengan ukuran sebenarnya, seret kotaknya ke mana saja di sekitar layar utama
// (menempel ke tepi terdekat), atau pakai tombol Kiri/Atas/Bawah/Kanan, Cermin, Hanya <layar ini>, Matikan.
// Semua layar: resolusi dan skala (dengan hitung mundur untuk kembali sendiri).
Rectangle {
    id: root

    required property var m
    readonly property var primary: Displays.primary
    readonly property bool isPrimary: primary !== null && primary.name === m.name
    readonly property string place: Displays.placeOf(m)
    readonly property var cfg: Displays.conf(m.name)
    readonly property bool waiting: Displays.revert !== null && Displays.revert.prev[m.name] !== undefined
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
                    text: root.m.name + (root.isPrimary ? " · layar utama" : "")
                        + (root.m.disabled ? " · mati" : " · " + root.m.width + " × " + root.m.height + (root.m.scale !== 1 ? " · " + Math.round(root.m.scale * 100) + "%" : ""))
                }
            }
        }

        // Layar utama yang sedang dimatikan ("hanya HDMI")
        Txt {
            visible: root.isPrimary && root.m.disabled
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font.pixelSize: 12
            color: Theme.muted
            text: "Layar ini mati, tampilan hanya di layar lain."
        }
        Btn {
            visible: root.isPrimary && root.m.disabled
            Layout.fillWidth: true
            bg: Theme.frame
            label: "Nyalakan lagi"
            onClicked: Displays.set(root.m.name, { position: "" })
        }

        // Peta posisi: ukuran & letak sebenarnya, kotak layar ini bisa diseret
        Item {
            id: map
            readonly property bool usable: !root.isPrimary && root.primary !== null && !root.primary.disabled
                && !root.m.disabled && !root.m.mirrored
            visible: usable
            Layout.fillWidth: true
            implicitHeight: 170

            readonly property real pw: usable ? root.primary.width / root.primary.scale : 1
            readonly property real ph: usable ? root.primary.height / root.primary.scale : 1
            readonly property real ow: usable ? root.m.width / root.m.scale : 1
            readonly property real oh: usable ? root.m.height / root.m.scale : 1
            // Skala peta: layar utama di tengah, ruang selebar layar ini di tiap sisi
            readonly property real k: Math.min(width / (pw + 2 * ow), height / (ph + 2 * oh)) * 0.96
            readonly property real ox: (width - pw * k) / 2
            readonly property real oy: (height - ph * k) / 2

            Rectangle {
                x: map.ox; y: map.oy
                width: map.pw * map.k; height: map.ph * map.k
                radius: 6
                color: Theme.surface2
                Txt { anchors.centerIn: parent; font.pixelSize: 12; text: root.primary ? root.short(root.primary) : "" }
            }

            Rectangle {
                id: box
                readonly property real homeX: map.usable ? map.ox + (root.m.x - root.primary.x) * map.k : 0
                readonly property real homeY: map.usable ? map.oy + (root.m.y - root.primary.y) * map.k : 0
                x: homeX; y: homeY
                width: map.ow * map.k; height: map.oh * map.k
                radius: 6
                color: Theme.accent
                opacity: dragArea.drag.active ? 0.8 : 1
                Txt { anchors.centerIn: parent; font.pixelSize: 12; color: Theme.frame; text: root.short(root.m) }
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    cursorShape: dragArea.drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    drag.target: box
                    drag.minimumX: 0; drag.maximumX: map.width - box.width
                    drag.minimumY: 0; drag.maximumY: map.height - box.height
                    onReleased: {
                        if (!dragArea.drag.active && Math.abs(box.x - box.homeX) < 2 && Math.abs(box.y - box.homeY) < 2) return
                        // 10 piksel di peta = jarak tempel untuk sejajar atas/tengah/bawah
                        Displays.place(root.m.name, (box.x - map.ox) / map.k, (box.y - map.oy) / map.k, 10 / map.k)
                        box.x = Qt.binding(() => box.homeX)
                        box.y = Qt.binding(() => box.homeY)
                    }
                }
            }
        }
        Txt {
            visible: map.usable
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 11
            color: Theme.muted
            text: "Seret kotak " + root.short(root.m) + " untuk mengatur posisi"
        }

        Txt {
            visible: !root.isPrimary && (root.place === "only" || root.place === "mirror" || root.place === "off")
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font.pixelSize: 12
            color: Theme.muted
            text: root.place === "only" ? "Hanya layar ini yang menyala. Pilih posisi di bawah untuk memakai dua layar lagi."
                : root.place === "mirror" ? "Menampilkan isi yang sama dengan layar " + (root.primary ? root.short(root.primary) : "utama") + "."
                : "Layar ini dimatikan."
        }

        // Tombol cepat
        RowLayout {
            visible: !root.isPrimary && root.primary !== null
            Layout.fillWidth: true
            spacing: 4
            Repeater {
                model: [{ v: "left", t: "Kiri" }, { v: "up", t: "Atas" }, { v: "down", t: "Bawah" }, { v: "right", t: "Kanan" }]
                Btn {
                    required property var modelData
                    Layout.fillWidth: true
                    pad: 4
                    bg: Theme.frame
                    label: modelData.t
                    active: root.cfg.position === modelData.v && root.place !== "only"
                    onClicked: Displays.set(root.m.name, { position: modelData.v })
                }
            }
        }
        RowLayout {
            visible: !root.isPrimary && root.primary !== null
            Layout.fillWidth: true
            spacing: 4
            Btn { Layout.fillWidth: true; pad: 4; bg: Theme.frame; label: "Cermin"; active: root.place === "mirror"; onClicked: Displays.set(root.m.name, { position: "mirror" }) }
            Btn { Layout.fillWidth: true; pad: 4; bg: Theme.frame; label: "Hanya " + root.short(root.m); active: root.place === "only"; onClicked: Displays.only(root.m.name) }
            Btn { Layout.fillWidth: true; pad: 4; bg: Theme.frame; label: "Matikan"; active: root.place === "off"; onClicked: Displays.set(root.m.name, { position: "off" }) }
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

        // Konfirmasi setelah ganti resolusi/skala/"hanya layar ini"
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
}
