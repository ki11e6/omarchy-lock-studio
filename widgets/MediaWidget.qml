import QtQuick
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.Commons

// Now playing: title, artist, progress and transport controls for one MPRIS
// player. The player is read into a local before each use; a player torn
// down between two property reads has crashed the shell in omalock.
WidgetCard {
  id: media

  // A playing player first, then Spotify with a track, then anything with a
  // track; nothing to show hides the widget.
  readonly property var player: {
    var ps = Mpris.players ? Mpris.players.values : []
    var spotify = null
    var any = null
    for (var i = 0; i < ps.length; i++) {
      var p = ps[i]
      if (!p) continue
      if (p.isPlaying && p.trackTitle) return p
      if (!p.trackTitle) continue
      var name = (String(p.identity || "") + " " + String(p.desktopEntry || "")).toLowerCase()
      if (!spotify && name.indexOf("spotify") !== -1) spotify = p
      if (!any) any = p
    }
    return spotify || any
  }
  readonly property string title: player ? String(player.trackTitle || "") : ""
  readonly property string artist: player ? String(player.trackArtist || "") : ""
  readonly property bool playing: player ? player.isPlaying === true : false
  readonly property bool hasProgress: player ? (player.positionSupported && player.lengthSupported && player.length > 0) : false
  property real position: 0

  available: title.length > 0

  function syncPosition() {
    var p = player
    position = p && p.positionSupported ? Math.max(0, p.position) : 0
  }
  onPlayerChanged: { syncPosition(); syncArt() }
  onTitleChanged: { syncPosition(); syncArt() }

  Timer {
    interval: 1000
    repeat: true
    running: media.host && media.host.live && media.playing && media.hasProgress
    onTriggered: media.syncPosition()
  }

  // ---- Album art ----------------------------------------------------------
  // Remote art is fetched only from these hosts, matched on a label boundary
  // so a lookalike ("evilscdn.co") never passes. Any player in the session
  // can set the URL, and it is read before authentication, so this list is
  // the whole boundary for automatic requests from the lock screen.
  readonly property var artHosts: ["scdn.co"]
  readonly property string artCachePath: host ? host.designsDir + "/.cache/album-art/cover.png" : ""
  property string artSource: ""
  property string pendingArtUrl: ""
  property string fetchingArtUrl: ""
  property string currentArtUrl: ""
  property int artVersion: 0

  function hostAllowed(h) {
    for (var i = 0; i < artHosts.length; i++) {
      var a = artHosts[i]
      if (h === a) return true
      var suffix = "." + a
      if (h.length > suffix.length && h.slice(-suffix.length) === suffix) return true
    }
    return false
  }

  // Null unless https:// on an allowed host with no userinfo, port or
  // control characters.
  function remoteArtUrl(raw) {
    if (!raw || raw.indexOf("https://") !== 0) return null
    for (var i = 0; i < raw.length; i++) {
      var c = raw.charCodeAt(i)
      if (c <= 0x20 || c === 0x7f) return null
    }
    var authority = raw.substring(8).split(/[/?#]/)[0]
    if (!authority || authority.indexOf("@") !== -1 || authority.indexOf(":") !== -1) return null
    return hostAllowed(authority.toLowerCase()) ? raw : null
  }

  function syncArt() {
    var p = player
    var raw = p && p.trackArtUrl ? String(p.trackArtUrl).trim() : ""
    if (raw === currentArtUrl) return
    currentArtUrl = raw
    pendingArtUrl = ""
    artSource = ""
    if (raw.indexOf("file://") === 0) {
      var local = raw.substring(7)
      try { local = decodeURIComponent(local) } catch (e) {}
      artSource = Util.fileUrl(local)
      return
    }
    if (raw.charAt(0) === "/") { artSource = Util.fileUrl(raw); return }
    var remote = remoteArtUrl(raw)
    if (!remote || !host || artCachePath.length === 0) return
    pendingArtUrl = remote
    if (!artFetch.running) startArtFetch()
  }

  // One fetch at a time: stopping a running one would kill only the wrapper
  // bash and orphan its curl, and its exit would be read as the new track's.
  // A track change mid-fetch is picked up in onExited instead.
  function startArtFetch() {
    if (!pendingArtUrl || !host) return
    fetchingArtUrl = pendingArtUrl
    artFetch.command = ["/usr/bin/bash", host.widgetsDir + "/fetch-image.sh", fetchingArtUrl, artCachePath]
    artFetch.running = true
  }

  Connections {
    target: media.player
    ignoreUnknownSignals: true
    function onTrackArtUrlChanged() { media.syncArt() }
    function onPositionChanged() { media.syncPosition() }
    function onIsPlayingChanged() { media.syncPosition() }
  }

  Process {
    id: artFetch
    clearEnvironment: true
    environment: ({ "PATH": "/usr/bin" })
    onExited: function(exitCode) {
      var fetched = media.fetchingArtUrl
      media.fetchingArtUrl = ""
      if (fetched !== media.currentArtUrl) {
        if (media.pendingArtUrl === media.currentArtUrl) Qt.callLater(media.startArtFetch)
        return
      }
      if (exitCode === 0) {
        media.artVersion += 1
        media.artSource = Util.fileUrl(media.artCachePath) + "?v=" + media.artVersion
      } else media.artSource = ""
    }
  }

  Component.onCompleted: { syncPosition(); syncArt() }

  // ---- Layout -------------------------------------------------------------
  readonly property real artSize: Style.space(64)
  readonly property real textWidth: Style.space(220)

  Row {
    spacing: Style.space(12)

    Rectangle {
      width: media.artSize
      height: media.artSize
      radius: Style.space(6)
      color: Qt.rgba(media.textColor.r, media.textColor.g, media.textColor.b, 0.08)
      clip: true
      anchors.verticalCenter: parent.verticalCenter

      Image {
        id: art
        anchors.fill: parent
        source: media.artSource
        visible: status === Image.Ready
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize.width: Math.round(media.artSize * 2)
        sourceSize.height: Math.round(media.artSize * 2)
      }
      Text {
        anchors.centerIn: parent
        visible: !art.visible
        text: "󰎈"
        color: media.dimTextColor
        font.family: Style.font.family
        font.pixelSize: Math.round(media.artSize * 0.45)
      }
    }

    Column {
      width: media.textWidth
      spacing: Style.space(4)
      anchors.verticalCenter: parent.verticalCenter

      Text {
        width: parent.width
        text: media.title
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: media.textColor
        font.family: media.fontFamily
        font.pixelSize: Style.font.body
        font.weight: Font.DemiBold
      }
      Text {
        width: parent.width
        visible: text.length > 0
        text: media.artist
        textFormat: Text.PlainText
        elide: Text.ElideRight
        color: media.dimTextColor
        font.family: media.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      Rectangle {
        width: parent.width
        height: Math.max(2, Style.space(3))
        radius: height / 2
        visible: media.hasProgress
        color: Qt.rgba(media.textColor.r, media.textColor.g, media.textColor.b, 0.2)
        Rectangle {
          height: parent.height
          radius: parent.radius
          color: media.textColor
          width: media.player && media.player.length > 0 ? parent.width * Math.min(1, media.position / media.player.length) : 0
        }
      }

      Row {
        spacing: Style.space(16)

        component Control: Text {
          id: control
          property bool enabledControl: true
          signal activated()
          opacity: enabledControl ? 1 : 0.35
          color: media.textColor
          font.family: Style.font.family
          font.pixelSize: Math.round(Style.font.heading * 1.2)
          MouseArea {
            anchors.fill: parent
            enabled: control.enabledControl
            cursorShape: Qt.PointingHandCursor
            onClicked: { control.activated(); media.interacted() }
          }
        }

        Control {
          text: "󰒮"
          enabledControl: media.player ? media.player.canGoPrevious === true : false
          onActivated: { var p = media.player; if (p && p.canGoPrevious) p.previous() }
        }
        Control {
          text: media.playing ? "󰏤" : "󰐊"
          enabledControl: media.player ? media.player.canTogglePlaying === true : false
          onActivated: { var p = media.player; if (p && p.canTogglePlaying) p.togglePlaying() }
        }
        Control {
          text: "󰒭"
          enabledControl: media.player ? media.player.canGoNext === true : false
          onActivated: { var p = media.player; if (p && p.canGoNext) p.next() }
        }
      }
    }
  }
}
