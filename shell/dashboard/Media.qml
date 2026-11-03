import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.config
import qs.widgets

// Kartu pemutar musik/video yang sedang aktif (MPRIS). Tersembunyi kalau tidak ada pemutar.
Item {
    id: root

    readonly property var player: {
        const p = Mpris.players.values
        for (let i = 0; i < p.length; i++) if (p[i].isPlaying) return p[i]
        return p.length > 0 ? p[0] : null
    }

    implicitHeight: player ? 86 : 0
    visible: player !== null

    Rectangle {
        id: art
        width: 70; height: 70; radius: 14
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.surface2
        clip: true
        Image { anchors.fill: parent; source: root.player ? root.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
        Txt { anchors.centerIn: parent; mono: true; text: Icons.music; font.pixelSize: 28; color: Theme.accent; visible: !parent.children[0].visible }
    }

    Column {
        anchors { left: art.right; leftMargin: 14; right: parent.right; verticalCenter: parent.verticalCenter }
        spacing: 3
        Txt { width: parent.width; elide: Text.ElideRight; font.weight: Font.DemiBold; text: root.player ? (root.player.trackTitle || root.player.identity) : "" }
        Txt { width: parent.width; elide: Text.ElideRight; color: Theme.muted; font.pixelSize: 13; text: root.player ? (root.player.trackArtist || root.player.identity) : "" }
        Row {
            spacing: 14
            topPadding: 4
            Repeater {
                model: [
                    { ic: Icons.prev, act: () => root.player.previous(), ok: root.player && root.player.canGoPrevious },
                    { ic: root.player && root.player.isPlaying ? Icons.pause : Icons.play, act: () => root.player.togglePlaying(), ok: root.player && root.player.canTogglePlaying },
                    { ic: Icons.next, act: () => root.player.next(), ok: root.player && root.player.canGoNext }
                ]
                Txt {
                    required property var modelData
                    text: modelData.ic
                    mono: true
                    font.pixelSize: 22
                    color: modelData.ok ? Theme.text : Theme.muted
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (parent.modelData.ok) parent.modelData.act() }
                }
            }
        }
    }
}
