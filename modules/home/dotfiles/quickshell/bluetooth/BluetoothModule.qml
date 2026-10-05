import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
  id: root
  property var theme: DefaultTheme {}
  property string font: "Hack Nerd Font"
  property string iconFont: "Symbols Nerd Font"

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool powered: root.adapter ? root.adapter.enabled : false
  readonly property bool scanning: root.adapter ? root.adapter.discovering : false
  readonly property var devices: Bluetooth.devices
  readonly property int connectedCount: {
    var n = 0;
    for (const d of root.devices.values) if (d.connected) n++;
    return n;
  }

  IpcHandler {
    target: "bluetooth"

    function toggle(): void {
      btPanel.visible = !btPanel.visible
      if (btPanel.visible) {
        root.searchText = "";
        searchInput.forceActiveFocus();
      }
    }
  }

  property string searchText: ""

  readonly property var filteredDevices: {
    const q = root.searchText.trim().toLowerCase();
    if (q === "") return root.devices.values;
    return root.devices.values.filter(d => (d.name || "").toLowerCase().includes(q));
  }

  function setPower(on) {
    if (root.adapter) root.adapter.enabled = on;
  }

  function toggleScan() {
    if (root.adapter) root.adapter.discovering = !root.adapter.discovering;
  }

  PanelWindow {
    id: btPanel
    visible: false
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-bluetooth"

    exclusionMode: ExclusionMode.Ignore

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }

    // Dark overlay backdrop
    MouseArea {
      anchors.fill: parent
      onClicked: btPanel.visible = false

      Rectangle {
        anchors.fill: parent
        color: root.theme.bgOverlay
      }
    }

    // Bluetooth box
    Rectangle {
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.rightMargin: 12
      anchors.topMargin: 44
      width: 380
      height: 500
      radius: 16
      color: root.theme.bgBase
      border.color: root.theme.bgBorder
      border.width: 1

      MouseArea {
        anchors.fill: parent
        onClicked: event => event.accepted = true
      }

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          Text {
            text: root.powered ? "\uF293" : "\uF294"
            color: root.powered ? root.theme.accentPrimary : root.theme.textMuted
            font.pixelSize: 16
            font.family: root.iconFont
          }

          Text {
            text: "Bluetooth"
            color: root.theme.textPrimary
            font.pixelSize: 14
            font.family: root.font
            font.bold: true
          }

          Text {
            text: root.connectedCount + " connected"
            color: root.connectedCount > 0 ? root.theme.accentGreen : root.theme.textMuted
            font.pixelSize: 11
            font.family: root.font
            Layout.alignment: Qt.AlignVCenter
          }

          Item { Layout.fillWidth: true }

          // Power toggle
          Rectangle {
            width: 44
            height: 24
            radius: 12
            color: root.powered ? root.theme.accentGreen : root.theme.bgSurface
            Accessible.role: Accessible.Button
            Accessible.name: root.powered ? "Turn Bluetooth off" : "Turn Bluetooth on"

            Behavior on color {
              ColorAnimation { duration: 150 }
            }

            Rectangle {
              width: 20
              height: 20
              radius: 10
              color: root.theme.bgBase
              anchors.verticalCenter: parent.verticalCenter
              x: root.powered ? parent.width - width - 2 : 2

              Behavior on x {
                NumberAnimation { duration: 150 }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.setPower(!root.powered)
            }
          }
        }

        // Search bar
        Rectangle {
          Layout.fillWidth: true
          height: 36
          radius: 8
          color: root.theme.bgSurface
          border.color: searchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
          border.width: 1

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
              text: "\uF349"
              color: root.theme.textMuted
              font.pixelSize: 13
              font.family: root.iconFont
              Layout.alignment: Qt.AlignVCenter
            }

            TextInput {
              id: searchInput
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              color: root.theme.textPrimary
              font.pixelSize: 13
              font.family: root.font
              clip: true
              selectByMouse: true
              Accessible.role: Accessible.EditableText
              Accessible.name: "Search bluetooth devices"
              onTextChanged: root.searchText = text

              Keys.onEscapePressed: btPanel.visible = false
            }

            Text {
              text: "Search devices..."
              color: root.theme.textMuted
              font.pixelSize: 13
              font.family: root.font
              visible: searchInput.text === "" && !searchInput.activeFocus
            }

            // Scan button
            Rectangle {
              Layout.preferredWidth: 28
              Layout.preferredHeight: 28
              radius: 14
              color: root.scanning ? root.theme.bgSelected : (scanHover.containsMouse ? root.theme.bgHover : "transparent")
              Accessible.role: Accessible.Button
              Accessible.name: root.scanning ? "Stop scanning" : "Start scanning"
              enabled: root.powered

              Text {
                anchors.centerIn: parent
                text: root.scanning ? "\uF1F8" : "\uF210"
                color: root.scanning ? root.theme.accentCyan : root.theme.textMuted
                font.pixelSize: 14
                font.family: root.iconFont
              }

              MouseArea {
                id: scanHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleScan()
              }
            }
          }
        }

        // Device list
        Rectangle {
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 8
          color: root.theme.bgSurface
          clip: true

          ListView {
            id: deviceList
            anchors.fill: parent
            anchors.margins: 4
            spacing: 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.filteredDevices

            delegate: Rectangle {
              id: del
              required property var modelData

              property bool paired: modelData.paired || modelData.bonded
              property bool busy: modelData.pairing

              width: deviceList.width
              height: 48
              radius: 6
              color: deviceHover.containsMouse ? root.theme.bgHover : "transparent"

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 6
                spacing: 10

                // Device icon
                Rectangle {
                  Layout.preferredWidth: 30
                  Layout.preferredHeight: 30
                  radius: 15
                  color: root.theme.bgBase

                  Text {
                    anchors.centerIn: parent
                    text: modelData.connected ? "\uF293" : "\uF294"
                    color: modelData.connected ? root.theme.accentGreen : root.theme.textMuted
                    font.pixelSize: 16
                    font.family: root.iconFont
                  }
                }

                // Name + state
                Column {
                  Layout.fillWidth: true
                  Layout.alignment: Qt.AlignVCenter
                  spacing: 2

                  Text {
                    text: modelData.name || modelData.address || "Unknown device"
                    color: root.theme.textPrimary
                    font.pixelSize: 12
                    font.family: root.font
                    elide: Text.ElideMiddle
                    width: parent.width
                  }

                  Text {
                    text: {
                      if (modelData.pairing) return "Pairing...";
                      if (modelData.connected) return "Connected";
                      if (del.paired) return "Paired";
                      return "Available";
                    }
                    color: {
                      if (modelData.connected) return root.theme.accentGreen;
                      if (modelData.pairing) return root.theme.accentOrange;
                      if (del.paired) return root.theme.accentCyan;
                      return root.theme.textMuted;
                    }
                    font.pixelSize: 10
                    font.family: root.font
                  }
                }

                // Battery
                Text {
                  text: modelData.batteryAvailable ? modelData.battery + "%" : ""
                  color: root.theme.textMuted
                  font.pixelSize: 10
                  font.family: root.font
                  visible: modelData.batteryAvailable
                }

                // Action button
                Rectangle {
                  Layout.preferredWidth: actionLabel.implicitWidth + 20
                  Layout.preferredHeight: 26
                  radius: 13
                  color: {
                    if (del.busy) return root.theme.bgSelected;
                    if (modelData.connected) return root.theme.accentRed;
                    return root.theme.accentPrimary;
                  }

                  Text {
                    id: actionLabel
                    anchors.centerIn: parent
                    text: {
                      if (del.busy) return "…";
                      if (modelData.connected) return "Disconnect";
                      return "Connect";
                    }
                    color: "#ffffff"
                    font.pixelSize: 10
                    font.family: root.font
                    font.bold: true
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      if (del.busy) return;
                      if (modelData.connected) {
                        modelData.disconnect();
                      } else {
                        modelData.connect();
                      }
                    }
                  }
                }
              }

              MouseArea {
                id: deviceHover
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  modelData.forget();
                }
              }
            }

            // Empty state
            Text {
              anchors.centerIn: parent
              text: root.powered ? (root.scanning ? "Scanning for devices..." : "No devices found\nPress scan to look for devices") : "Bluetooth is off"
              color: root.theme.textMuted
              font.pixelSize: 12
              font.family: root.font
              horizontalAlignment: Text.AlignHCenter
              visible: deviceList.count === 0
            }
          }
        }

        // Footer hints
        RowLayout {
          Layout.fillWidth: true
          spacing: 12

          Row {
            spacing: 4
            Text { text: "click"; color: root.theme.accentGreen; font.pixelSize: 10; font.family: root.font }
            Text { text: "connect"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
          }

          Row {
            spacing: 4
            Text { text: "right-click"; color: root.theme.accentRed; font.pixelSize: 10; font.family: root.font }
            Text { text: "forget"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
          }

          Item { Layout.fillWidth: true }

          Text {
            text: root.scanning ? "\uF1F8" : "\uF293"
            color: root.scanning ? root.theme.accentCyan : root.theme.textMuted
            font.pixelSize: 12
            font.family: root.iconFont
            visible: root.powered
          }
        }
      }
    }
  }
}