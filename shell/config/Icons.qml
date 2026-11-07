pragma Singleton

import QtQuick
import Quickshell

// Ikon dari JetBrainsMono Nerd Font (Material Design Icons). Pakai: Icons.wifi
Singleton {
    function g(cp) { return String.fromCodePoint(cp) }

    readonly property string wifi: g(0xF05A9)
    readonly property string wifiOff: g(0xF05AA)
    readonly property string ethernet: g(0xF0200)
    readonly property string bluetooth: g(0xF00AF)
    readonly property string bluetoothOff: g(0xF00B2)
    readonly property string headphones: g(0xF02CB)
    readonly property string speaker: g(0xF04C3)
    readonly property string monitor: g(0xF0379)
    readonly property string camera: g(0xF0100)
    readonly property string coffee: g(0xF0176)
    readonly property string sun: g(0xF05A8)
    readonly property string moon: g(0xF0F65)
    readonly property string crop: g(0xF019E)
    readonly property string screens: g(0xF0E51)
    readonly property string mouse: g(0xF037D)
    readonly property string keyboard: g(0xF030C)
    readonly property string gamepad: g(0xF0297)
    readonly property string phone: g(0xF011C)
    readonly property string laptop: g(0xF0322)
    readonly property string volume: g(0xF057E)
    readonly property string volumeMute: g(0xF0581)
    readonly property string brightness: g(0xF00E0)
    readonly property string battery: g(0xF0079)
    readonly property string batteryCharging: g(0xF0084)
    readonly property string bell: g(0xF009A)
    readonly property string bellOff: g(0xF009B)
    readonly property string night: g(0xF0594)
    readonly property string power: g(0xF0425)
    readonly property string lock: g(0xF033E)
    readonly property string logout: g(0xF0343)
    readonly property string restart: g(0xF0709)
    readonly property string search: g(0xF0349)
    readonly property string music: g(0xF075A)
    readonly property string play: g(0xF040A)
    readonly property string pause: g(0xF03E4)
    readonly property string next: g(0xF04AD)
    readonly property string prev: g(0xF04AE)
    readonly property string app: g(0xF08C6)
    readonly property string terminal: g(0xF018D)
    readonly property string calculator: g(0xF00EC)
    readonly property string close: g(0xF0156)
    readonly property string arch: g(0xF08C7)
    readonly property string cpu: g(0xF061A)
    readonly property string memory: g(0xF035B)
    readonly property string chevron: g(0xF0142)
    readonly property string chevronDown: g(0xF0140)
    readonly property string cog: g(0xF0493)
    readonly property string eye: g(0xF0208)
    readonly property string eyeOff: g(0xF0209)

    // Ikon kekuatan sinyal WiFi (0..1), versi bergembok untuk jaringan berkunci
    function wifiStrength(s, locked) {
        const lvl = s > 0.75 ? 3 : s > 0.5 ? 2 : s > 0.25 ? 1 : 0
        return g([0xF091F, 0xF0922, 0xF0925, 0xF0928][lvl] + (locked ? 2 : 0))
    }
}
