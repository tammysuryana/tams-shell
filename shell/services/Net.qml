pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

// Status jaringan (NetworkManager): nama WiFi yang tersambung, atau kabel.
Singleton {
    id: root

    readonly property var wifiDevice: {
        const d = Networking.devices.values
        for (let i = 0; i < d.length; i++)
            if (d[i].type === DeviceType.Wifi) return d[i]
        return null
    }
    readonly property bool wired: {
        const d = Networking.devices.values
        for (let i = 0; i < d.length; i++)
            if (d[i].type === DeviceType.Wired && d[i].connected) return true
        return false
    }
    readonly property var wifiNetwork: {
        if (!wifiDevice) return null
        const n = wifiDevice.networks.values
        for (let i = 0; i < n.length; i++)
            if (n[i].connected) return n[i]
        return null
    }
    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property string label: wired ? "Kabel" : wifiNetwork ? wifiNetwork.name : (wifiOn ? "Tidak tersambung" : "WiFi mati")
    readonly property real signal: wifiNetwork ? wifiNetwork.signalStrength : 0

    function toggleWifi() { Networking.wifiEnabled = !Networking.wifiEnabled }
}
