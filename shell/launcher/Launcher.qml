import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services
import qs.widgets

// Launcher yang keluar dari sisi kiri bingkai.
// Ketik untuk cari aplikasi · "=" hitung · ">" jalankan perintah. Panah atas/bawah, Enter, Esc.
Item {
    id: root

    property bool open: false
    readonly property int panelWidth: 520
    readonly property int r: Theme.panelRadius
    property int sel: 0

    width: open ? panelWidth + r : 0
    visible: width > 0
    clip: true
    Behavior on width { NumberAnimation { duration: Theme.anim; easing.type: Easing.OutCubic } }

    onOpenChanged: {
        if (open) { input.text = ""; root.sel = 0; focusTimer.restart() }
    }
    // Fokus keyboard layer-shell baru diberikan compositor sesaat setelah panel muncul,
    // jadi pasang fokus lagi sebentar kemudian supaya huruf pertama tidak hilang.
    Timer { id: focusTimer; interval: 30; repeat: true; property int n: 0
        onTriggered: { input.forceActiveFocus(); if (++n >= 5) { n = 0; stop() } } }

    readonly property string query: input.text.trim()
    readonly property var results: {
        const q = root.query
        if (q.startsWith("=")) return [{ kind: "calc", title: Calc.compute(q.slice(1)), sub: q.slice(1).trim() }]
        if (q.startsWith(">")) return [{ kind: "cmd", title: q.slice(1).trim(), sub: "Jalankan perintah" }]
        return Apps.search(q).slice(0, 8).map(e => ({ kind: "app", title: e.name, sub: e.genericName || e.comment || "", entry: e }))
    }

    function activate(i) {
        const it = root.results[i]
        if (!it) return
        if (it.kind === "app") it.entry.execute()
        else if (it.kind === "cmd" && it.title !== "") Quickshell.execDetached(["sh", "-c", it.title])
        else if (it.kind === "calc") Quickshell.clipboardText = it.title
        Panels.closeAll()
    }

    // Telinga cekung kanan-atas & kanan-bawah
    Corner { corner: "tl"; x: Math.max(0, root.width - root.r); y: 0; size: root.r }
    Corner { corner: "bl"; x: Math.max(0, root.width - root.r); y: root.height - root.r; size: root.r }

    Rectangle {
        id: body
        width: root.panelWidth
        x: root.width - root.r - root.panelWidth
        height: parent.height
        color: Theme.frame
        radius: root.r
        Rectangle { width: root.r; height: parent.height; color: Theme.frame }

        Column {
            anchors { fill: parent; margins: 28 }
            spacing: 16

            // Kolom ketik
            Item {
                width: parent.width
                height: 48
                Txt { id: caret; text: "›"; mono: true; font.pixelSize: 28; font.weight: Font.Bold; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                TextInput {
                    id: input
                    anchors { left: caret.right; leftMargin: 12; right: parent.right; verticalCenter: parent.verticalCenter }
                    color: Theme.text
                    font.family: Theme.mono
                    font.pixelSize: 26
                    font.weight: Font.Bold
                    selectionColor: Theme.accent
                    cursorDelegate: Rectangle { width: 3; color: Theme.accent }
                    Keys.onEscapePressed: Panels.closeAll()
                    Keys.onDownPressed: root.sel = Math.min(root.sel + 1, root.results.length - 1)
                    Keys.onUpPressed: root.sel = Math.max(root.sel - 1, 0)
                    Keys.onReturnPressed: root.activate(root.sel)
                    Keys.onEnterPressed: root.activate(root.sel)
                    onTextChanged: root.sel = 0
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2; color: Theme.accent }
            }

            Txt {
                color: Theme.muted
                font.pixelSize: 13
                textFormat: Text.StyledText
                text: "Ketik untuk cari · <font color='" + Theme.accent + "'>=</font> hitung · <font color='" + Theme.accent + "'>&gt;</font> perintah · Esc tutup"
            }

            Repeater {
                model: root.results
                Rectangle {
                    required property var modelData
                    required property int index
                    readonly property bool on: index === root.sel
                    width: parent.width
                    height: 62
                    radius: 16
                    color: on ? Theme.surface : mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.03) : "transparent"
                    Rectangle { visible: parent.on; width: 3; height: parent.height - 16; anchors.verticalCenter: parent.verticalCenter; radius: 2; color: Theme.accent }

                    Rectangle {
                        id: ic
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        width: 42; height: 42; radius: 12
                        color: Theme.surface2
                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 28
                            visible: parent.parent.modelData.kind === "app"
                            source: parent.parent.modelData.entry ? Quickshell.iconPath(parent.parent.modelData.entry.icon, "application-x-executable") : ""
                        }
                        Txt {
                            anchors.centerIn: parent
                            visible: parent.parent.modelData.kind !== "app"
                            mono: true; font.pixelSize: 22; color: Theme.accent
                            text: parent.parent.modelData.kind === "calc" ? Icons.calculator : Icons.terminal
                        }
                    }
                    Column {
                        anchors { left: ic.right; leftMargin: 14; right: parent.right; rightMargin: 80; verticalCenter: parent.verticalCenter }
                        spacing: 2
                        Txt { width: parent.width; elide: Text.ElideRight; font.pixelSize: 16; mono: parent.parent.modelData.kind !== "app"; text: parent.parent.modelData.title }
                        Txt { width: parent.width; elide: Text.ElideRight; font.pixelSize: 13; color: Theme.muted; text: parent.parent.modelData.sub; visible: text !== "" }
                    }
                    Txt { visible: parent.on; anchors.right: parent.right; anchors.rightMargin: 14; anchors.verticalCenter: parent.verticalCenter; mono: true; font.pixelSize: 12; color: Theme.muted
                          text: parent.modelData.kind === "calc" ? "Enter salin" : "Enter" }

                    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: root.sel = parent.index; onClicked: root.activate(parent.index) }
                }
            }

            Txt { visible: root.results.length === 0; text: "Tidak ada yang cocok"; color: Theme.muted }
        }
    }
}
