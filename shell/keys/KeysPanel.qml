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
    property int maxHeight: 700        // lebih tinggi dari ini: isinya digulir
    // Lebar tetap tiap kolom (3 kolom, margin 28, jarak antarkolom 28)
    readonly property real colW: (panelWidth - 56 - 56) / 3
    readonly property int r: Theme.panelRadius

    width: panelWidth + r * 2
    height: open ? body.implicitHeight : 0
    visible: height > 0
    clip: true
    Behavior on height { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }

    onOpenChanged: if (open) { Keybinds.refresh(); body.forceActiveFocus() }

    // Lebar deretan kotak tombol (sama dengan ukuran Chip di bawah)
    FontMetrics { id: chipFont; font.family: Theme.mono; font.pixelSize: 11 }
    function chipsWidth(parts) {
        let w = 0
        for (const p of parts) {
            const t = chipFont.advanceWidth(p)
            w += (p === " / " || p === "…") ? t : Math.max(22, t + 12)
        }
        return w + 4 * Math.max(0, parts.length - 1) + 1
    }

    // Bagi deretan kotak tombol ke beberapa baris selebar maks. maxW (pemisah "/" ikut ke baris berikutnya)
    function chipLines(parts, maxW) {
        const lines = [[]]
        let w = 0
        for (const p of parts) {
            const pw = root.chipsWidth([p]) + 4
            if (w + pw > maxW && lines[lines.length - 1].length > 0 && p !== " / " && p !== "…") { lines.push([]); w = 0 }
            lines[lines.length - 1].push(p)
            w += pw
        }
        return lines
    }

    // Daftar dari model QML belum tentu array JS biasa: salin dulu
    function arr(l) {
        const out = []
        for (let i = 0; l && i < l.length; i++) out.push(l[i])
        return out
    }

    function keyParts(r) {
        const k = arr(r.keys)
        if (r.range) return [k[0], "…", k[k.length - 1]]
        // Banyak tombol pendek (huruf, panah): satu kotak saja, mis. "← → ↑ ↓"
        if (k.length > 2 && k.every(x => x.length <= 2)) return [k.join(" ")]
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
        implicitHeight: Math.min(content.implicitHeight + 56, root.maxHeight)
        color: Theme.frame
        radius: root.r
        focus: true
        Keys.onEscapePressed: Panels.closeAll()
        Keys.onDownPressed: flick.scrollBy(60)
        Keys.onUpPressed: flick.scrollBy(-60)
        Keys.onPressed: e => {
            if (e.key === Qt.Key_PageDown) flick.scrollBy(flick.height - 60)
            else if (e.key === Qt.Key_PageUp) flick.scrollBy(-(flick.height - 60))
        }
        // sudut bawah lurus (menyambung ke bingkai)
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: root.r; color: Theme.frame }

        Flickable {
            id: flick
            anchors { fill: parent; margins: 28; bottomMargin: 0 }
            contentHeight: content.implicitHeight + 28
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            function scrollBy(d) { contentY = Math.max(0, Math.min(contentHeight - height, contentY + d)) }

            ColumnLayout {
                id: content
                width: flick.width
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
                            Layout.preferredWidth: root.colW
                            Layout.maximumWidth: root.colW
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
                Txt { Layout.fillWidth: true; Layout.minimumWidth: 110; text: row.modelData.text; wrapMode: Text.Wrap; font.pixelSize: 13 }
                // Kotak tombol; dibagi ke beberapa baris (dihitung sekali di JS, tanpa Flow
                // supaya tata letaknya tidak saling bergantung)
                Column {
                    readonly property var lines: root.chipLines(root.arr(row.modelData.mods).concat(root.keyParts(row.modelData)), root.colW - 120)
                    Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    spacing: 4
                    Repeater {
                        model: parent.lines
                        Row {
                            required property var modelData
                            anchors.right: parent.right
                            spacing: 4
                            Repeater {
                                model: parent.modelData
                                Chip { required property string modelData; label: modelData; plain: modelData === " / " || modelData === "…" }
                            }
                        }
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
