pragma ComponentBehavior: Bound

import QtQuick
import qs.config
import qs.services
import qs.widgets

// Widget pemutar musik + lirik karaoke di atas wallpaper. Muncul saat ada pemutar MPRIS aktif.
// Tampilan saja (kendali putar ada di dashboard). Lirik dari Lyrics service (lrclib.net).
Item {
    id: root

    readonly property var player: Lyrics.player
    readonly property int pw: parent ? parent.width : 0
    readonly property int ph: parent ? parent.height : 0
    visible: player !== null
    implicitWidth: 440
    implicitHeight: card.implicitHeight
    width: implicitWidth
    height: implicitHeight

    // Posisi tersimpan (piksel); -1 = default pojok kiri-bawah.
    function place() {
        x = Settings.mediaX >= 0 ? Math.min(Settings.mediaX, Math.max(0, pw - width)) : (Theme.edge + 40)
        y = Settings.mediaY >= 0 ? Math.min(Settings.mediaY, Math.max(0, ph - height)) : (ph - height - Theme.edge - 40)
    }
    function save() {
        x = Math.max(0, Math.min(x, pw - width))
        y = Math.max(0, Math.min(y, ph - height))
        Settings.set("mediaX", Math.round(x))
        Settings.set("mediaY", Math.round(y))
    }
    Component.onCompleted: place()
    onPhChanged: if (Settings.mediaX < 0) place()   // tempatkan default setelah ukuran layar siap

    // Seret untuk memindahkan; posisi disimpan saat dilepas.
    DragHandler {
        target: root
        onActiveChanged: if (!active) root.save()
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: 20
        color: Qt.rgba(Theme.frame.r, Theme.frame.g, Theme.frame.b, 0.72)
        implicitHeight: content.implicitHeight + 32
        border.width: 1
        border.color: Qt.rgba(Theme.line.r, Theme.line.g, Theme.line.b, 0.4)

        Column {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
            spacing: 12

            // Sedang diputar: sampul + judul + artis
            Row {
                width: parent.width
                spacing: 12
                Rectangle {
                    id: art
                    width: 56; height: 56; radius: 12; clip: true; color: Theme.surface2
                    Image {
                        anchors.fill: parent
                        source: root.player ? root.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }
                    Txt {
                        anchors.centerIn: parent; mono: true; text: Icons.music
                        font.pixelSize: 22; color: Theme.accent
                        visible: !art.children[0].visible
                    }
                }
                Column {
                    width: parent.width - 56 - 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Txt {
                        width: parent.width; elide: Text.ElideRight
                        font.weight: Font.DemiBold; font.pixelSize: 15
                        text: root.player ? (root.player.trackTitle || root.player.identity || "") : ""
                    }
                    Txt {
                        width: parent.width; elide: Text.ElideRight
                        color: Theme.muted; font.pixelSize: 12
                        text: root.player ? (root.player.trackArtist || "") : ""
                    }
                }
            }

            // Lirik karaoke: 7 baris, baris aktif (indeks Lyrics.before) paling menonjol.
            Column {
                width: parent.width
                spacing: 4
                visible: Lyrics.status === "ok"
                Repeater {
                    model: 7
                    delegate: Txt {
                        required property int index
                        readonly property int dist: Math.abs(index - Lyrics.before)
                        width: content.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: Lyrics.slots[index] ?? ""
                        font.pixelSize: dist === 0 ? 18 : (dist === 1 ? 14 : 12)
                        font.weight: dist === 0 ? Font.Bold : Font.Normal
                        color: dist === 0 ? Theme.accent : Theme.text
                        opacity: dist === 0 ? 1 : (dist === 1 ? 0.6 : (dist === 2 ? 0.35 : 0.15))
                        Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on font.pixelSize { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }
                }
            }

            // Status saat lirik belum/tidak ada
            Txt {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                visible: Lyrics.status !== "ok"
                color: Theme.muted
                font.pixelSize: 13
                text: Lyrics.status === "loading" ? "Memuat lirik…"
                    : Lyrics.status === "not_found" ? "Lirik tidak ditemukan"
                    : Lyrics.status === "no_info" ? "—"
                    : ""
            }
        }
    }
}
