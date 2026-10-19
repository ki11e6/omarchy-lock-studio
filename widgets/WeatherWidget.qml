import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "file:///usr/share/omarchy/shell/plugins/panels/weather/Model.js" as WeatherModel

// Current weather for the location set in Omarchy's weather panel. Fetches
// only while the lock is live, at most every 15 minutes, and hides itself on
// any failure. If an Omarchy update moves Model.js, only this widget's
// Loader fails.
WidgetCard {
  id: weather

  readonly property string curlBin: "/usr/bin/curl"
  readonly property int refreshMs: 15 * 60 * 1000
  readonly property bool live: host ? host.live : false
  readonly property string unit: settings && settings.unit ? String(settings.unit) : "auto"

  property var location: ({ name: "", latitude: null, longitude: null })
  property bool locationLoaded: false
  readonly property bool hasCoordinates: location.latitude !== null && location.longitude !== null
  property double lastFetch: 0

  property bool hasWeather: false
  property var current: null
  property string country: ""
  readonly property bool imperial: WeatherModel.shouldUseImperial(unit, Qt.locale().name, country)
  readonly property string temp: current ? (imperial ? current.temp_F : current.temp_C) + "°" + (imperial ? "F" : "C") : ""
  readonly property string glyph: current ? WeatherModel.currentIcon(current, "") : ""

  available: hasWeather && temp.length > 0

  FileView {
    path: Quickshell.env("HOME") + "/.local/state/omarchy/settings/weather.json"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: weather.setLocation(WeatherModel.parseLocationFile(text()))
    onLoadFailed: weather.setLocation(WeatherModel.parseLocationFile(""))
  }

  function setLocation(loc) {
    location = loc
    locationLoaded = true
    lastFetch = 0
    maybeRefresh()
  }

  function maybeRefresh() {
    if (live && locationLoaded && Date.now() - lastFetch > refreshMs) refresh()
  }

  onLiveChanged: maybeRefresh()

  Timer {
    interval: weather.refreshMs
    repeat: true
    running: weather.live
    onTriggered: weather.refresh()
  }

  function refresh() {
    if (!locationLoaded || fetchProc.running) return
    lastFetch = Date.now()
    var url
    if (hasCoordinates) {
      fetchProc.source = "open-meteo"
      url = "https://api.open-meteo.com/v1/forecast"
        + "?latitude=" + encodeURIComponent(String(location.latitude))
        + "&longitude=" + encodeURIComponent(String(location.longitude))
        + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,is_day"
        + "&timezone=auto"
    } else {
      fetchProc.source = "wttr"
      url = "https://wttr.in/" + WeatherModel.wttrLocationQuery(location.name, location.latitude, location.longitude) + "?format=j1"
    }
    fetchProc.command = [curlBin, "-fsS", "--max-time", "8", url]
    fetchProc.running = true
  }

  Process {
    id: fetchProc
    property string source: ""
    clearEnvironment: true
    stdout: StdioCollector { id: fetchOut; waitForEnd: true }
    onExited: function(exitCode) {
      var cur = null
      var area = ""
      if (exitCode === 0) {
        try {
          var parsed = JSON.parse(String(fetchOut.text || ""))
          if (fetchProc.source === "open-meteo") cur = WeatherModel.openMeteoCurrentCondition(parsed)
          else if (parsed && parsed.current_condition && parsed.current_condition[0]) {
            cur = parsed.current_condition[0]
            var a = parsed.nearest_area && parsed.nearest_area[0]
            area = a && a.country && a.country[0] ? String(a.country[0].value || "") : ""
          }
        } catch (e) { cur = null }
      }
      weather.current = cur
      weather.country = area
      weather.hasWeather = cur !== null
    }
  }

  Component.onCompleted: maybeRefresh()

  Row {
    spacing: Style.space(10)

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: weather.glyph
      visible: text.length > 0
      color: weather.textColor
      font.family: Style.font.family
      font.pixelSize: Math.round(Style.font.heading * 1.4)
    }
    Column {
      anchors.verticalCenter: parent.verticalCenter
      Text {
        text: weather.temp
        color: weather.textColor
        font.family: weather.fontFamily
        font.pixelSize: Style.font.heading
        font.weight: Font.DemiBold
      }
      Text {
        visible: text.length > 0
        text: weather.location.name
        textFormat: Text.PlainText
        color: weather.dimTextColor
        font.family: weather.fontFamily
        font.pixelSize: Style.font.bodySmall
      }
    }
  }
}
