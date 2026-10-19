import QtQuick
import Quickshell.Services.Pipewire
import qs.Commons
import qs.Ui

// Output volume and mute for the default PipeWire sink.
WidgetCard {
  id: volume

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool ready: sink !== null && sink.audio !== null
  readonly property bool muted: ready ? sink.audio.muted : false
  readonly property real level: ready ? sink.audio.volume : 0

  available: ready

  // The sink's audio properties only stay live while it is tracked.
  PwObjectTracker { objects: volume.sink ? [volume.sink] : [] }

  function glyph() {
    if (muted || level <= 0) return "󰖁"
    if (level < 0.5) return "󰕿"
    return "󰕾"
  }

  function toggleMute() {
    var s = sink
    if (s && s.audio) s.audio.muted = !s.audio.muted
  }

  Row {
    spacing: Style.space(12)

    Text {
      width: Style.space(22)
      anchors.verticalCenter: parent.verticalCenter
      text: volume.glyph()
      color: volume.textColor
      font.family: Style.font.family
      font.pixelSize: Math.round(Style.font.heading * 1.2)
      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: { volume.toggleMute(); volume.interacted() }
      }
    }

    PanelSlider {
      anchors.verticalCenter: parent.verticalCenter
      implicitWidth: Style.space(180)
      minimum: 0
      maximum: 1
      step: 0.05
      value: volume.level
      onMoved: function(v) { var s = volume.sink; if (s && s.audio) s.audio.volume = v }
      onReleased: volume.interacted()
      onRightClicked: { volume.toggleMute(); volume.interacted() }
    }
  }
}
