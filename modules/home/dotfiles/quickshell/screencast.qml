import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

ScreencastWindow {
    id: root
    visible: false

    ScreencastSourceModel {
        id: sourceModel
    }
}