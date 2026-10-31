pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    PanelWindow {
        id: surface

        color: content.backgroundColor
        screen: content.preferredScreen
        visible: content.windowModelReady && content.preferredScreen !== null
        implicitWidth: content.preferredWidth
        implicitHeight: content.preferredHeight
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-screencast"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        exclusionMode: ExclusionMode.Ignore

        PickerWindow {
            id: content

            anchors.fill: parent
            hostWindow: surface
        }
    }
}