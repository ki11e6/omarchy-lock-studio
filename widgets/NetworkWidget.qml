import QtQuick
import Quickshell.Networking
import qs.Commons

// Connection status from NetworkManager via Quickshell.Networking, the same
// source Omarchy's network panel reads. Wired wins over Wi-Fi; offline hides.
WidgetCard {
  id: network

  readonly property var devices: Networking.devices ? Networking.devices.values : []
  readonly property var wired: findDevice(DeviceType.Wired)
  readonly property var wifi: findDevice(DeviceType.Wifi)
  readonly property bool wiredConnected: !!(wired && wired.connected)
  readonly property var wifiNetwork: {
    var list = wifi && wifi.networks ? wifi.networks.values : []
    for (var i = 0; i < list.length; i++) if (list[i] && list[i].connected) return list[i]
    return null
  }
  readonly property int strength: wifiNetwork ? Math.round((wifiNetwork.signalStrength || 0) * 100) : -1

  readonly property string label: wiredConnected ? String(wired.name || "Ethernet") : (wifiNetwork ? String(wifiNetwork.name || "") : "")
  // 20% bands, the same glyphs as Omarchy's network panel.
  readonly property string glyph: {
    if (wiredConnected) return "󰈀"
    var icons = ["󰤯", "󰤟", "󰤢", "󰤥", "󰤨"]
    return icons[Math.max(0, Math.min(4, Math.ceil(strength / 20) - 1))]
  }

  available: label.length > 0

  function findDevice(type) {
    var fallback = null
    for (var i = 0; i < devices.length; i++) {
      var d = devices[i]
      if (!d || d.type !== type) continue
      if (d.connected) return d
      if (!fallback) fallback = d
    }
    return fallback
  }

  Row {
    spacing: Style.space(8)

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: network.glyph
      color: network.textColor
      font.family: Style.font.family
      font.pixelSize: Math.round(Style.font.heading * 1.2)
    }
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: network.label
      textFormat: Text.PlainText
      elide: Text.ElideRight
      width: Math.min(implicitWidth, Style.space(200))
      color: network.textColor
      font.family: network.fontFamily
      font.pixelSize: Style.font.body
    }
  }
}
