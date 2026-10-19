import QtQuick
import qs.Commons

// Time and date in the user's own Qt format strings. An empty time format
// follows the 12/24-hour setting. Designs keep their own dates; only this
// widget uses the custom formats.
WidgetCard {
  id: clock

  readonly property string timeFormat: settings && settings.timeFormat ? String(settings.timeFormat) : ""
  readonly property string dateFormat: settings && typeof settings.dateFormat === "string" ? settings.dateFormat : "dddd, MMMM d"
  readonly property bool twelveHour: host ? host.twelveHour : false
  property date now: new Date()

  Timer {
    interval: 1000
    repeat: true
    running: clock.host ? clock.host.live : false
    triggeredOnStart: true
    onTriggered: clock.now = new Date()
  }

  Column {
    Text {
      text: Qt.formatDateTime(clock.now, clock.timeFormat || (clock.twelveHour ? "h:mm AP" : "HH:mm"))
      textFormat: Text.PlainText
      color: clock.textColor
      font.family: clock.fontFamily
      font.pixelSize: Math.round(Style.font.heading * 2)
      font.weight: Font.DemiBold
    }
    Text {
      visible: text.length > 0
      text: clock.dateFormat.length > 0 ? Qt.formatDateTime(clock.now, clock.dateFormat) : ""
      textFormat: Text.PlainText
      color: clock.dimTextColor
      font.family: clock.fontFamily
      font.pixelSize: Style.font.body
    }
  }
}
