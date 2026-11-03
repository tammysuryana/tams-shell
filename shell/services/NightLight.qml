pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Lampu malam (layar kekuningan) lewat hyprsunset.
Singleton {
    id: root

    property bool on: false
    property int temperature: 4500

    function toggle() { root.on = !root.on }

    Process {
        id: proc
        running: root.on
        command: ["hyprsunset", "-t", String(root.temperature)]
    }
}
