import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// The picker's Settings tab: personal settings, background, blanking and the
// widget overlay on the left, a live thumbnail of the lock on the right.
// Every control writes through the service facade straight away, so the
// thumbnail follows each change.
Item {
  id: root

  // Set by the picker.
  property var service: null
  property bool active: false
  property string designPath: ""
  property color foreground: Commons.Color.menu.text
  property color accent: Commons.Color.accent
  property color muted: Util.alpha(foreground, 0.55)
  property string fontFamily: Style.font.family

  // A text field let go of the keyboard (Esc); the picker takes it back.
  signal leaveField()
  signal lockRequested()

  // While zenity is up the picker steps back so its window can show.
  readonly property bool browsing: zenity.running

  readonly property var settings: service && service.settings ? service.settings : ({})
  readonly property var widgets: service && service.widgetSettings ? service.widgetSettings : ({})
  readonly property real labelWidth: Style.space(120)

  function setting(key, fallback) {
    return key in root.settings ? root.settings[key] : fallback
  }

  function save(key, value) {
    if (root.service) root.service.setSetting(key, value)
  }

  function saveWidget(name, patch) {
    if (root.service) root.service.setWidget(name, patch)
  }

  // Clock samples tick while the tab shows.
  property date now: new Date()
  Timer {
    interval: 1000
    repeat: true
    running: root.active
    onTriggered: root.now = new Date()
  }

  property string browseTarget: ""
  function browse(target) {
    if (zenity.running) return
    root.browseTarget = target
    zenity.running = true
  }

  Process {
    id: zenity
    command: ["/usr/bin/zenity", "--file-selection", "--title=Choose an image",
      "--file-filter=Images | *.png *.jpg *.jpeg *.webp *.gif"]
    clearEnvironment: true
    environment: ({
      HOME: Quickshell.env("HOME") || "",
      XDG_RUNTIME_DIR: Quickshell.env("XDG_RUNTIME_DIR") || "",
      WAYLAND_DISPLAY: Quickshell.env("WAYLAND_DISPLAY") || "",
      DBUS_SESSION_BUS_ADDRESS: Quickshell.env("DBUS_SESSION_BUS_ADDRESS") || ""
    })
    stdout: StdioCollector { id: zenityOut; waitForEnd: true }
    onExited: function(exitCode) {
      var picked = String(zenityOut.text || "").trim()
      if (exitCode === 0 && picked.length > 0) root.save(root.browseTarget, picked)
    }
  }

  readonly property var cornerOptions: [
    { value: "top-left", label: "Top left" },
    { value: "top-right", label: "Top right" },
    { value: "bottom-left", label: "Bottom left" },
    { value: "bottom-right", label: "Bottom right" }
  ]

  component SectionTitle: Text {
    color: root.foreground
    font.family: root.fontFamily
    font.pixelSize: Style.font.title
    font.weight: Font.Bold
    topPadding: Style.space(10)
  }

  component Label: Text {
    width: root.labelWidth
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    color: root.foreground
    elide: Text.ElideRight
    font.family: root.fontFamily
    font.pixelSize: Style.font.body
  }

  component Caption: Text {
    width: parent ? parent.width : 0
    wrapMode: Text.Wrap
    color: root.muted
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }

  // Esc hands the keyboard back to the picker instead of closing it.
  component Field: TextField {
    font.family: root.fontFamily
    Keys.onEscapePressed: function(event) { root.leaveField(); event.accepted = true }
  }

  component SmallButton: Button {
    foreground: root.foreground
    accent: root.accent
    fontFamily: root.fontFamily
  }

  // ================= form =================
  Flickable {
    id: form
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    width: Math.round(parent.width * 0.56)
    contentHeight: formColumn.implicitHeight + Style.space(20)
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    rightMargin: Style.space(14)

    Controls.ScrollBar.vertical: Controls.ScrollBar {
      id: formBar
      policy: Controls.ScrollBar.AsNeeded
      contentItem: Rectangle {
        implicitWidth: Style.space(6)
        radius: width / 2
        color: Util.alpha(root.foreground, formBar.pressed ? 0.5 : (formBar.hovered ? 0.4 : 0.26))
      }
    }

    Column {
      id: formColumn
      width: form.width - form.rightMargin
      spacing: Style.space(10)

      // ---- You ------------------------------------------------------------
      SectionTitle { text: "You" }

      Row {
        spacing: Style.spacing.controlGap
        Label { text: "Display name" }
        Field {
          width: Style.space(240)
          placeholderText: "Your login name"
          text: root.setting("displayName", "")
          onEditingFinished: if (text.trim() !== root.setting("displayName", "")) root.save("displayName", text)
        }
      }

      Row {
        spacing: Style.spacing.controlGap
        Label { text: "Avatar" }
        Field {
          width: Style.space(240)
          placeholderText: "AccountsService icon or ~/.face"
          text: root.setting("avatar", "")
          onEditingFinished: if (text.trim() !== root.setting("avatar", "")) root.save("avatar", text)
        }
        SmallButton { text: "Browse"; onClicked: root.browse("avatar") }
        SmallButton { text: "From URL"; onClicked: urlRow.visible = !urlRow.visible }
      }

      Row {
        id: urlRow
        visible: false
        spacing: Style.spacing.controlGap
        Item { width: root.labelWidth; height: 1 }
        Field {
          id: urlField
          width: Style.space(240)
          placeholderText: "https://…"
          onAccepted: if (root.service) root.service.downloadAvatar(text)
        }
        SmallButton {
          text: root.service && root.service.avatarDownloadStatus === "downloading" ? "Downloading…" : "Download"
          onClicked: if (root.service) root.service.downloadAvatar(urlField.text)
        }
      }

      Caption {
        visible: urlRow.visible && root.service !== null && root.service.avatarDownloadStatus.length > 0
        leftPadding: root.labelWidth + Style.spacing.controlGap
        text: !root.service ? ""
          : root.service.avatarDownloadStatus === "failed" ? "That URL didn't give an image. It must be https, under 8 MB, and a PNG, JPEG, GIF, WebP or BMP."
          : root.service.avatarDownloadStatus === "ok" ? "Saved as your avatar."
          : "Downloading…"
        color: root.service && root.service.avatarDownloadStatus === "failed" ? Commons.Color.urgent : root.muted
      }

      // ---- Background -----------------------------------------------------
      SectionTitle { text: "Background" }

      Row {
        spacing: Style.spacing.controlGap
        Label { text: "Wallpaper" }
        Field {
          width: Style.space(240)
          placeholderText: "Omarchy background"
          text: root.setting("wallpaper", "")
          onEditingFinished: if (text.trim() !== root.setting("wallpaper", "")) root.save("wallpaper", text)
        }
        SmallButton { text: "Browse"; onClicked: root.browse("wallpaper") }
        SmallButton { text: "Use Omarchy background"; onClicked: root.save("wallpaper", "") }
      }

      Row {
        spacing: Style.spacing.controlGap
        Label { text: "Blur" }
        ToggleSwitch {
          anchors.verticalCenter: parent.verticalCenter
          checked: root.service ? root.service.wallpaperBlur : true
          onToggled: root.save("wallpaperBlur", !checked)
        }
      }

      Row {
        spacing: Style.spacing.controlGap
        Label { text: "Dim" }
        PanelSlider {
          id: dimSlider
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(260)
          minimum: 0
          maximum: 1
          step: 0.05
          value: root.service ? root.service.wallpaperDim : 0
          onReleased: function(v) { root.save("wallpaperDim", Math.round(v * 100) / 100) }
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: Math.round(dimSlider.liveValue * 100) + "%"
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
        }
      }

      Caption { text: "Wallpaper, blur and dim apply to the 10 designs that show a wallpaper (Classic, Bento, Halo, Postcard and others)." }

      // ---- Screen blanking ------------------------------------------------
      SectionTitle { text: "Screen blanking" }

      Row {
        spacing: Style.spacing.controlGap
        Label { text: "When idle" }
        Dropdown {
          width: Style.space(260)
          showLabel: false
          fontFamily: root.fontFamily
          accent: root.accent
          value: root.service ? root.service.blankMode : "off"
          options: [
            { value: "off", label: "Turn display off" },
            { value: "dim", label: "Dim" },
            { value: "never", label: "Never" }
          ]
          onChanged: function(next) { root.save("blankMode", next) }
        }
      }

      Row {
        visible: !root.service || root.service.blankMode !== "never"
        spacing: Style.spacing.controlGap
        Label { text: "After" }
        PanelSlider {
          id: delaySlider
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(260)
          minimum: 1
          maximum: 300
          step: 1
          integer: true
          value: root.service ? root.service.blankDelay : 5
          onReleased: function(v) { root.save("blankDelay", Math.round(v)) }
        }
        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: Math.round(delaySlider.liveValue) + " s"
          color: root.muted
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
        }
      }

      Caption { text: "Dim darkens the lock but keeps the panel on, so it uses more power than turning the display off." }

      // ---- Widgets --------------------------------------------------------
      SectionTitle { text: "Widgets" }

      Repeater {
        model: [
          { id: "clock", label: "Clock" },
          { id: "avatar", label: "Avatar" },
          { id: "weather", label: "Weather" },
          { id: "network", label: "Network" },
          { id: "media", label: "Now playing" },
          { id: "volume", label: "Volume" },
          { id: "power", label: "Power" }
        ]
        delegate: Column {
          id: widgetRow
          required property var modelData
          readonly property var cfg: root.widgets[modelData.id] || ({})
          spacing: Style.space(6)

          Row {
            spacing: Style.spacing.controlGap
            Label { text: widgetRow.modelData.label }
            ToggleSwitch {
              anchors.verticalCenter: parent.verticalCenter
              checked: widgetRow.cfg.enabled === true
              onToggled: root.saveWidget(widgetRow.modelData.id, { enabled: !checked })
            }
            Dropdown {
              width: Style.space(170)
              showLabel: false
              fontFamily: root.fontFamily
              accent: root.accent
              value: widgetRow.cfg.corner || ""
              options: root.cornerOptions
              onChanged: function(next) { root.saveWidget(widgetRow.modelData.id, { corner: next }) }
            }
            Dropdown {
              visible: widgetRow.modelData.id === "weather"
              width: Style.space(150)
              showLabel: false
              fontFamily: root.fontFamily
              accent: root.accent
              value: widgetRow.cfg.unit || "auto"
              options: [
                { value: "auto", label: "Units: auto" },
                { value: "metric", label: "°C, km/h" },
                { value: "imperial", label: "°F, mph" }
              ]
              onChanged: function(next) { root.saveWidget("weather", { unit: next }) }
            }
            Dropdown {
              visible: widgetRow.modelData.id === "avatar"
              width: Style.space(150)
              showLabel: false
              fontFamily: root.fontFamily
              accent: root.accent
              value: widgetRow.cfg.shape || "circle"
              options: [
                { value: "circle", label: "Circle" },
                { value: "square", label: "Square" }
              ]
              onChanged: function(next) { root.saveWidget("avatar", { shape: next }) }
            }
          }

          // Qt date format strings, e.g. "HH:mm" or "dddd, MMMM d".
          Row {
            visible: widgetRow.modelData.id === "clock"
            spacing: Style.spacing.controlGap
            Label { text: "Time format" }
            Field {
              id: timeField
              width: Style.space(240)
              placeholderText: root.service && root.service.twelveHour ? "h:mm AP" : "HH:mm"
              text: widgetRow.cfg.timeFormat || ""
              onEditingFinished: if (text !== (widgetRow.cfg.timeFormat || "")) root.saveWidget("clock", { timeFormat: text })
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: Qt.formatDateTime(root.now, timeField.text.length > 0 ? timeField.text : timeField.placeholderText)
              color: root.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }
          }
          Row {
            visible: widgetRow.modelData.id === "clock"
            spacing: Style.spacing.controlGap
            Label { text: "Date format" }
            Field {
              id: dateField
              width: Style.space(240)
              placeholderText: "Date format"
              text: widgetRow.cfg.dateFormat || ""
              onEditingFinished: if (text !== (widgetRow.cfg.dateFormat || "")) root.saveWidget("clock", { dateFormat: text })
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: Qt.formatDateTime(root.now, dateField.text)
              color: root.muted
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
            }
          }
        }
      }

      Caption { text: "Widgets sit over every design. Weather fetches from Open-Meteo or wttr.in while it shows; album art is only fetched from Spotify's image host." }
    }
  }

  // ================= live preview =================
  Column {
    anchors.top: parent.top
    anchors.left: form.right
    anchors.leftMargin: Style.space(20)
    anchors.right: parent.right
    spacing: Style.space(12)

    Item {
      id: thumb
      width: parent.width
      height: Math.round(width * 9 / 16)

      Rectangle {
        anchors.fill: parent
        radius: 6
        color: Util.alpha(root.foreground, 0.06)
      }

      // A thumbnail only: input is off so a widget button here (Suspend,
      // say) can't act on a click.
      Loader {
        anchors.fill: parent
        active: root.active && root.service !== null
        sourceComponent: Item {
          clip: true
          enabled: false
          Item {
            width: 1920
            height: 1080
            scale: thumb.width / 1920
            transformOrigin: Item.TopLeft

            LockHost {
              anchors.fill: parent
              designPath: root.designPath.length > 0 ? root.designPath : root.service.fallbackDesignPath
              fallbackPath: root.service.fallbackDesignPath
              backgroundPath: root.service.backgroundPath
              backgroundVersion: root.service.backgroundVersion
              fingerprintConfigured: root.service.fingerprintConfigured
              inputEnabled: false
              loadBackground: true
              videoPlaying: false
              twelveHour: root.service.twelveHour
              displayFont: root.service.displayFont
              avatarPath: root.service.avatarPath
              avatarVersion: root.service.avatarVersion
              displayName: root.service.displayName
              wallpaperBlur: root.service.wallpaperBlur
              wallpaperDim: root.service.wallpaperDim
            }

            Loader {
              anchors.fill: parent
              z: 10
              source: root.service.widgetLayerUrl
              onLoaded: {
                item.live = Qt.binding(function() { return root.active })
                item.config = Qt.binding(function() { return root.widgets })
                item.cache = root.service.widgetCache
                item.twelveHour = Qt.binding(function() { return root.service ? root.service.twelveHour : false })
                item.displayFont = Qt.binding(function() { return root.service ? root.service.displayFont : Style.font.family })
                item.avatarPath = Qt.binding(function() { return root.service ? root.service.avatarPath : "" })
                item.avatarVersion = Qt.binding(function() { return root.service ? root.service.avatarVersion : 0 })
                item.displayName = Qt.binding(function() { return root.service ? root.service.displayName : "" })
                item.designsDir = Qt.binding(function() { return root.service ? root.service.designsDir : "" })
              }
            }
          }
        }
      }
    }

    Row {
      spacing: Style.spacing.controlGap
      SmallButton {
        text: "Preview full screen"
        iconText: "󰈈"
        onClicked: if (root.service) root.service.showPreview("")
      }
      SmallButton {
        text: "Lock now"
        iconText: "󰌾"
        onClicked: root.lockRequested()
      }
    }

    Caption { text: "Changes apply right away, to this preview and to the lock." }
  }
}
