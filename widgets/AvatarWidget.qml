import QtQuick
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Commons as Commons

// The user's picture, masked to a circle or a rounded square, with the
// display name under it. No picture shows the initial instead.
WidgetCard {
  id: avatar

  readonly property real size: Style.space(72)
  readonly property bool square: settings && settings.shape === "square"
  readonly property real maskRadius: square ? Style.cornerRadius : size / 2
  readonly property string name: host && host.displayName.length > 0 ? host.displayName : (Quickshell.env("USER") || Quickshell.env("LOGNAME") || "user")
  readonly property string source: host && host.avatarPath.length > 0
    ? Util.fileUrl(host.avatarPath) + "?v=" + host.avatarVersion : ""
  readonly property bool showsImage: source.length > 0 && picture.status === Image.Ready

  Column {
    spacing: Style.space(8)

    Item {
      width: avatar.size
      height: avatar.size
      anchors.horizontalCenter: parent.horizontalCenter

      Rectangle {
        anchors.fill: parent
        radius: avatar.maskRadius
        color: Commons.Color.lock.borderActive
        antialiasing: true
        visible: !avatar.showsImage
        Text {
          anchors.centerIn: parent
          text: avatar.name.charAt(0).toUpperCase()
          color: Commons.Color.background
          font.family: Style.font.family
          font.pixelSize: Math.round(avatar.size * 0.5)
          font.weight: Font.Bold
        }
      }

      // Masked with a copy of the shape, as designs/Avatar.qml does.
      Image {
        id: picture
        anchors.fill: parent
        source: avatar.source
        visible: avatar.showsImage
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        mipmap: true
        sourceSize.width: Math.round(avatar.size * 2)
        sourceSize.height: Math.round(avatar.size * 2)
        layer.enabled: avatar.source.length > 0
        layer.smooth: true
        layer.effect: MultiEffect {
          maskEnabled: true
          maskSource: shapeMask
          maskThresholdMin: 0.5
          maskSpreadAtMin: 0.05
        }
      }

      Item {
        id: shapeMask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle {
          anchors.fill: parent
          radius: avatar.maskRadius
          color: "white"
          antialiasing: true
        }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: avatar.name
      textFormat: Text.PlainText
      color: avatar.textColor
      font.family: avatar.fontFamily
      font.pixelSize: Style.font.body
    }
  }
}
