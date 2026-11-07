import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.widgets

// Daftar pintasan keyboard yang tumbuh dari bingkai bawah (Super + /). Dibaca ulang dari
// Hyprland setiap kali dibuka, jadi pintasan buatan sendiri ikut tampil.
Item {
    id: root

    property bool open: false
    property int panelWidth: 1100
    readonly property int r: Theme.panelRadius

    width: panelWidth + r * 2
    height: open ? body.implicitHeight : 0
    visible: height > 0
    clip: true
    Behavior on height { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }

    onOpenChanged: if (open) { Keybinds.refresh(); body.forceActiveFocus() }

    function keyParts(r) {
        const k = r.keys
        if (r.range) return [k[0], "…", k[k.length - 1]]
        const out = []
        for (let i = 0; i < k.length; i++) {
            if (i > 0) out.push(" / ")
            out.push(k[i])
        }
        return out
    }

    // Bagi bagian ke 3 kolom serata mungkin (yang terbanyak dulu), urutan asli tetap dijaga
    readonly property var columns: {
        const secs = Keybinds.sections.map((s, i) => ({ s: s, i: i, n: s.rows.length + 2 }))
        const cols = [[], [], []], load = [0, 0, 0]
        for (const x of secs.slice().sort((a, b) => b.n - a.n)) {
            const c = load.indexOf(Math.min(...load))
            cols[c].push(x)
            load[c] += x.n
        }
        return cols.filter(c => c.length > 0)
            .map(c => c.sort((a, b) => a.i - b.i))
            .sort((a, b) => a[0].i - b[0].i)
            .map(c => c.map(x => x.s))
    }

    // "Telinga" cekung kiri & kanan agar panel menyatu dengan bingkai bawah
    Corner { corner: "br"; size: Math.min(root.r, root.height); x: root.r - size; y: root.height - size }
    Corner { corner: "bl"; size: Math.min(root.r, root.height); x: root.r + root.panelWidth; y: root.height - size }

    Rectangle {
        id: body
        x: root.r
        y: root.height - height
        width: root.panelWidth
        height: implicitHeight
        implicitHeight: content.implicitHeight + 56
        color: Theme.frame
        radius: root.r
        focus: true
        Keys.onEscapePressed: Panels.closeAll()
        // sudut bawah lurus (menyambung ke bingkai)
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: root.r; color: Theme.frame }

        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 28 }
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                Txt { text: "Pintasan keyboard"; font.pixelSize: 22; font.weight: Font.Bold; Layout.fillWidth: true }
                Txt { text: "Super + /  buka · Esc  tutup"; color: Theme.muted; font.pixelSize: 12 }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 28
                Repeater {
                    model: root.columns
                    ColumnLayout {
                        id: column
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.alignment: Qt.AlignTop
                        spacing: 14
                        Repeater {
                            model: column.modelData
                            Section { Layout.fillWidth: true }
                        }
                    }
                }
            }
        }
    }

    component Section: ColumnLayout {
        id: sec
        required property var modelData
        spacing: 2
        Txt {
            text: sec.modelData.title
            font.pixelSize: 11
            font.letterSpacing: 2
            font.capitalization: Font.AllUppercase
            color: Theme.muted
            Layout.bottomMargin: 4
        }
        Repeater {
            model: sec.modelData.rows
            RowLayout {
                id: row
                required property var modelData
                Layout.fillWidth: true
                Layout.minimumHeight: 28
                spacing: 10
                Txt { Layout.fillWidth: true; text: row.modelData.text; wrapMode: Text.Wrap; font.pixelSize: 13 }
                Row {
                    spacing: 4
                    Repeater {
                        model: row.modelData.mods
                        Chip { required property string modelData; label: modelData }
                    }
                    Repeater {
                        // Rentang angka ditulis "1 … 0", pilihan lain dipisah "/"
                        model: root.keyParts(row.modelData)
                        Chip { required property string modelData; label: modelData; plain: modelData === " / " || modelData === "…" }
                    }
                }
            }
        }
    }

    component Chip: Rectangle {
        property string label
        property bool plain: false
        implicitWidth: plain ? t.implicitWidth : Math.max(22, t.implicitWidth + 12)
        implicitHeight: 22
        radius: 6
        color: plain ? "transparent" : Theme.surface2
        Txt { id: t; anchors.centerIn: parent; text: parent.label; mono: true; font.pixelSize: 11; color: parent.plain ? Theme.muted : Theme.text }
    }
}
