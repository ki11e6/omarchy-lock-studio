import QtQuick
import qs.Commons

// The overlay drawn above whichever design is live. No root MouseArea, so a
// click outside a widget still reaches the design. Each widget is its own
// file in its own Loader: one that fails to load only leaves its slot empty.
Item {
  id: overlay

  // Set by the service.
  property var config: ({})
  property var cache: null
  property bool live: false
  property bool twelveHour: false
  property string displayFont: Style.font.family
  property string avatarPath: ""
  property int avatarVersion: 0
  property string displayName: ""
  property string designsDir: ""

  readonly property string widgetsDir: decodeURIComponent(Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "").replace(/\/$/, ""))

  // Raised after any click on a widget control, so the service can wake the
  // display and hand keyboard focus back to the password field.
  signal interacted()

  readonly property real margin: Style.space(24)
  readonly property real spacing: Style.space(14)

  // Fixed stacking order inside a corner.
  readonly property var order: ["clock", "avatar", "weather", "network", "media", "volume", "power"]

  // Each corner builds its own Loaders. Moving an already loaded Loader into
  // another container left it unpainted, so a corner change recreates the
  // widget in its new corner instead.
  component Corner: Column {
    id: corner
    property string name: ""
    property bool alignRight: false
    // A string, so the Repeater only rebuilds when this corner's list changes.
    readonly property string names: overlay.order.filter(function(n) {
      var c = overlay.config ? overlay.config[n] : null
      return c && c.enabled === true && c.corner === corner.name
    }).join(",")
    spacing: overlay.spacing

    Repeater {
      model: corner.names.length > 0 ? corner.names.split(",") : []
      delegate: Loader {
        id: slot
        required property string modelData
        readonly property var settings: overlay.config && overlay.config[modelData] ? overlay.config[modelData] : ({})
        x: corner.alignRight ? corner.width - width : 0
        visible: status === Loader.Ready && item.available === true
        source: Qt.resolvedUrl(modelData.charAt(0).toUpperCase() + modelData.slice(1) + "Widget.qml")
        onLoaded: {
          item.host = overlay
          item.settings = Qt.binding(function() { return slot.settings })
        }
      }
    }
  }

  Corner {
    name: "top-left"
    anchors { top: parent.top; left: parent.left; margins: overlay.margin }
  }
  Corner {
    name: "top-right"
    alignRight: true
    anchors { top: parent.top; right: parent.right; margins: overlay.margin }
  }
  // Anchored at the bottom, so these grow upward as widgets are added.
  Corner {
    name: "bottom-left"
    anchors { bottom: parent.bottom; left: parent.left; margins: overlay.margin }
  }
  Corner {
    name: "bottom-right"
    alignRight: true
    anchors { bottom: parent.bottom; right: parent.right; margins: overlay.margin }
  }
}
