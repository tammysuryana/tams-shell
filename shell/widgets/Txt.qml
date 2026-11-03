import QtQuick
import qs.config

// Teks standar tams-shell. mono: true untuk angka/ikon (JetBrainsMono Nerd Font).
Text {
    property bool mono: false
    color: Theme.text
    font.family: mono ? Theme.mono : Theme.font
    font.pixelSize: Theme.fontSize
    verticalAlignment: Text.AlignVCenter
    renderType: Text.NativeRendering
}
