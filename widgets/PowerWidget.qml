import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons

// Session buttons, using the same commands and availability checks as
// Omarchy's own menu. Restart and Shut down need a second click within 3 s.
WidgetCard {
  id: power

  property bool suspendAllowed: false
  property bool hibernateAvailable: false
  // Which action is waiting for its confirming click, if any.
  property string armed: ""

  Process {
    command: ["bash", "-c", "omarchy-toggle-enabled suspend-off"]
    running: true
    onExited: function(exitCode) { power.suspendAllowed = exitCode !== 0 }
  }
  Process {
    command: ["bash", "-c", "omarchy-hibernation-available"]
    running: true
    onExited: function(exitCode) { power.hibernateAvailable = exitCode === 0 }
  }

  Timer {
    id: disarm
    interval: 3000
    onTriggered: power.armed = ""
  }

  function run(action, needsConfirm, argv) {
    if (needsConfirm && armed !== action) {
      armed = action
      disarm.restart()
      return
    }
    armed = ""
    disarm.stop()
    Quickshell.execDetached(argv)
  }

  Column {
    spacing: Style.space(6)

    Row {
      spacing: Style.space(18)

      component PowerButton: Text {
        id: button
        property string action: ""
        signal activated()
        color: power.armed === action ? Commons.Color.lock.textError : power.textColor
        font.family: Style.font.family
        font.pixelSize: Math.round(Style.font.heading * 1.4)
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: { button.activated(); power.interacted() }
        }
      }

      PowerButton {
        visible: power.suspendAllowed
        action: "suspend"
        text: "󰤄"
        onActivated: power.run("suspend", false, ["systemctl", "suspend"])
      }
      PowerButton {
        visible: power.hibernateAvailable
        action: "hibernate"
        text: "󰒲"
        onActivated: power.run("hibernate", false, ["systemctl", "hibernate"])
      }
      PowerButton {
        action: "restart"
        text: "󰜉"
        onActivated: power.run("restart", true, ["omarchy-system-reboot"])
      }
      PowerButton {
        action: "shutdown"
        text: "󰐥"
        onActivated: power.run("shutdown", true, ["omarchy-system-shutdown"])
      }
    }

    Text {
      visible: power.armed.length > 0
      text: power.armed === "restart" ? "Click again to restart" : "Click again to shut down"
      color: Commons.Color.lock.textError
      font.family: power.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
  }
}
