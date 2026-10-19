import QtQuick
import qs.Commons
import qs.Commons as Commons

// Shared backdrop for every widget: a translucent rounded card in the lock
// colors, so widgets stay legible over video and busy wallpapers.
Rectangle {
  id: card

  // Set by WidgetLayer: the layer itself and this widget's settings.
  property var host: null
  property var settings: ({})
  // A widget with nothing to show sets this false and its slot hides.
  property bool available: true

  readonly property color textColor: Commons.Color.lock.text
  readonly property color dimTextColor: Commons.Color.lock.placeholder
  readonly property string fontFamily: host ? host.displayFont : Style.font.family

  function interacted() { if (host) host.interacted() }

  default property alias content: inner.data
  property real padding: Style.space(14)

  implicitWidth: inner.childrenRect.width + padding * 2
  implicitHeight: inner.childrenRect.height + padding * 2
  width: implicitWidth
  height: implicitHeight
  radius: Math.max(Style.cornerRadius, Style.space(10))
  color: Qt.rgba(Commons.Color.lock.background.r, Commons.Color.lock.background.g, Commons.Color.lock.background.b, 0.6)

  Item {
    id: inner
    x: card.padding
    y: card.padding
    width: childrenRect.width
    height: childrenRect.height
  }
}
