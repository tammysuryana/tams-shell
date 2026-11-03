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
}
