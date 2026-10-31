import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets

ScreencastWindow {
    id: root
    visible: false
    width: 800
    height: 500

    property var theme: DefaultTheme {}
    property string font: "Hack Nerd Font"
    property string iconFont: "Symbols Nerd Font"

    // Theme-aware colors matching quickshell style
    readonly property color bgBase: theme.bgBase
    readonly property color bgSurface: theme.bgSurface
    readonly property color bgHover: "#1e2235"
    readonly property color bgSelected: "#283457"
    readonly property color bgBorder: "#32364a"
    readonly property color bgOverlay: "#88000000"

    readonly property color textPrimary: theme.textPrimary
    readonly property color textSecondary: theme.textSecondary
    readonly property color textMuted: theme.textMuted

    readonly property color accentPrimary: theme.accentPrimary
    readonly property color accentCyan: theme.accentCyan
    readonly property color accentGreen: theme.accentGreen
    readonly property color accentOrange: theme.accentOrange
    readonly property color accentRed: theme.accentRed

    // Screencast model
    ScreencastSourceModel {
        id: sourceModel
    }

    readonly property var screenEntries: sourceModel.screens
    readonly property var windowEntries: sourceModel.toplevels

    // UI state
    readonly property int selectedIndex: 0
    property int tabIndex: 0 // 0=Screen, 1=Window, 2=Region

    // Buttons/shortcuts
    IpcHandler {
        target: "screencast"
        function toggle(): void { root.visible = !root.visible }
    }

    // Panel window using WlrLayershell (matching quickshell-share-picker)
    PanelWindow {
        id: surface
        color: bgBase
        screen: sourceModel.preferredScreen
        visible: root.windowModelReady && sourceModel.preferredScreen !== null
        implicitWidth: 800
        implicitHeight: 500
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-screencast"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        exclusionMode: ExclusionMode.Ignore

        // Background overlay
        MouseArea {
            anchors.fill: parent
            onClicked: root.cancel()

            Rectangle {
                anchors.fill: parent
                color: bgOverlay
            }
        }

        // Main content area
        PickerWindow {
            id: content
            anchors.fill: parent
            hostWindow: surface

            // Tab bar for screen/window/region selection
            TabBar {
                id: tabBar
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                palette.buttonText: textPrimary
                palette.highlight: accentPrimary
                palette.highlightedText: textPrimary
                palette.windowText: textPrimary
                onCurrentIndexChanged: {
                    root.tabIndex = currentIndex
                }

                TabButton {
                    text: "Screen"
                    hoverEnabled: true
                    background: Rectangle {
                        color: tabIndex === 0 ? selectedColor : (tabHoverColor || tabColor)
                        border.color: borderColor
                        border.width: 1
                    }
                    contentItem: Text {
                        color: textPrimary
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: parent.text
                    }
                }
                TabButton {
                    text: "Window"
                    hoverEnabled: true
                    background: Rectangle {
                        color: tabIndex === 1 ? selectedColor : (tabHoverColor || tabColor)
                        border.color: borderColor
                        border.width: 1
                    }
                    contentItem: Text {
                        color: textPrimary
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: parent.text
                    }
                }
                TabButton {
                    text: "Region"
                    hoverEnabled: true
                    background: Rectangle {
                        color: tabIndex === 2 ? selectedColor : (tabHoverColor || tabColor)
                        border.color: borderColor
                        border.width: 1
                    }
                    contentItem: Text {
                        color: textPrimary
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: parent.text
                    }
                }
            }

            // Main content area below tabs
            StackLayout {
                anchors.fill: parent
                anchors.top: tabBar.bottom
                currentIndex: tabIndex
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Screen tab - show available screens with previews
                Item {
                    anchors.fill: parent

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            // Screen list on left
                            Rectangle {
                                Layout.preferredWidth: 300
                                Layout.fillHeight: true
                                color: bgSurface
                                border.color: borderColor
                                border.width: 1
                                radius: 6

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 6

                                    Text {
                                        text: "Screens"
                                        color: textPrimary
                                        font.pixelSize: 12
                                        font.family: font
                                        font.bold: true
                                    }

                                    ListView {
                                        id: screenList
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        spacing: 2
                                        model: screenEntries
                                        highlightMoveDuration: 80
                                        highlight: Rectangle {
                                            color: accentPrimary
                                            border.color: activeFocus ? accentPrimary : borderColor
                                            border.width: activeFocus ? 2 : 1
                                            radius: 4
                                        }

                                        delegate: Item {
                                            id: screenDelegate
                                            required property var modelData
                                            required property int index
                                            width: screenList.width - (screenList.scrollBar ? screenList.scrollBar.width + 4 : 0)
                                            height: 54

                                            Column {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.leftMargin: 12
                                                anchors.rightMargin: 12
                                                spacing: 2

                                                Text {
                                                    width: parent.width
                                                    color: textColor
                                                    elide: Text.ElideRight
                                                    font.weight: Font.DemiBold
                                                    text: modelData.name
                                                }

                                                Text {
                                                    width: parent.width
                                                    color: mutedTextColor
                                                    font.pixelSize: 11
                                                    elide: Text.ElideRight
                                                    text: modelData.width + "×" + modelData.height + " at " + modelData.x + ", " + modelData.y
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onEntered: {
                                                    // Show preview on hover
                                                }
                                                onClicked: {
                                                    screenList.currentIndex = screenDelegate.index;
                                                    root.selectScreen(modelData);
                                                }
                                                onDoubleClicked: {
                                                    screenList.currentIndex = screenDelegate.index;
                                                    root.finalizeSelection("screen:" + modelData.name);
                                                }
                                            }
                                        }

                                        ScrollBar.vertical: ScrollBar {
                                            policy: ScrollBar.AsNeeded
                                            width: 8
                                        }
                                    }
                                }

                                // Screen preview on right
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.minimumWidth: 200
                                    color: "#111318"
                                    radius: 4
                                    clip: true

                                    ScreencopyView {
                                        id: screenPreview
                                        anchors.centerIn: parent
                                        captureSource: selectedScreen ? selectedScreen.screen : null
                                        live: false
                                        paintCursor: false
                                        width: hasContent ? Math.min(parent.width, parent.height * screenPreview.sourceRatio) : 0
                                        height: hasContent ? width / screenPreview.sourceRatio : 0
                                    }

                                    Timer {
                                        id: screenPreviewRefreshTimer
                                        interval: 1000
                                        repeat: true
                                        running: windowModelReady && tabIndex === 0 && screenPreview.captureSource !== null
                                        onTriggered: screenPreview.captureFrame()
                                    }

                                    BusyIndicator {
                                        anchors.centerIn: parent
                                        anchors.verticalCenterOffset: -18
                                        width: 32
                                        height: 32
                                        running: visible
                                        visible: screenPreview.selection && screenPreview.captureSource && !screenPreview.hasContent
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        anchors.verticalCenterOffset: 22
                                        width: parent.width - 40
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
                                        color: "#c8cbd0"
                                        visible: !screenPreview.hasContent
                                        text: selectedScreen
                                            ? "Select a screen to preview"
                                            : "No screens available"
                                    }

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 52
                                        color: "#dd181a1f"
                                        visible: screenPreview.selection !== null

                                        Column {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 2

                                            Text {
                                                width: parent.width
                                                color: "#f5f6f7"
                                                elide: Text.ElideRight
                                                font.weight: Font.DemiBold
                                                text: screenPreview.selection ? screenPreview.selection.name : ""
                                            }

                                            Text {
                                                width: parent.width
                                                color: "#c8cbd0"
                                                elide: Text.ElideRight
                                                font.pixelSize: 11
                                                text: screenPreview.selection
                                                    ? screenPreview.selection.width + "×" + screenPreview.selection.height
                                                        + " · scale " + screenPreview.selection.scale
                                                        + (screenPreview.selection.refreshRate > 0
                                                            ? " · " + Math.round(screenPreview.selection.refreshRate) + " Hz"
                                                            : "")
                                                    : ""
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Action buttons at bottom
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                height: 44
                                radius: 8
                                color: bgSurface
                                border.color: borderColor
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    color: textPrimary
                                    font.pixelSize: 13
                                    font.family: font
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "Share Screen"
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 44
                                radius: 8
                                color: bgSurface
                                border.color: borderColor
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    color: textMuted
                                    font.pixelSize: 13
                                    font.family: font
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "Cancel"
                                }
                            }
                        }
                    }
                }

                // Window tab - show application windows
                Item {
                    anchors.fill: parent

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            // Window filter
                            Rectangle {
                                Layout.fillWidth: true
                                height: 44
                                radius: 8
                                color: bgSurface
                                border.color: borderColor
                                border.width: 1

                                TextField {
                                    id: windowFilter
                                    Layout.fillWidth: true
                                    placeholderText: "Filter windows…"
                                    palette.base: surfaceColor
                                    palette.text: textPrimary
                                    palette.placeholderText: textMuted
                                    palette.highlight: accentPrimary
                                    palette.highlightedText: tooltipTextColor
                                    text: windowFilterText
                                                    onTextEdited: {
                        root.windowFilterText = text;
                        root.refreshFilteredWindows();
                    }
                                                Keys.onDownPressed: event => {
                                                    root.moveWindowSelection(1);
                                                    event.accepted = true;
                                                }
                                                Keys.onUpPressed: event => {
                                                    root.moveWindowSelection(-1);
                                                    event.accepted = true;
                                                }
                                                Keys.onEscapePressed: event => {
                                                    if (text.length > 0) {
                                                        clear();
                                                        root.windowFilterText = "";
                                                        root.refreshFilteredWindows();
                                                    } else {
                                                        root.windowFilterActive = false;
                                                        windowList.forceActiveFocus();
                                                    }
                                                    event.accepted = true;
                                                }
                                                Keys.onReturnPressed: event => {
                                                    if (root.selectedWindow())
                                                        root.shareCurrent();
                                                    event.accepted = true;
                                                }
                                }
                            }

                            // Window list
                            Rectangle {
                                Layout.preferredWidth: 300
                                Layout.fillHeight: true
                                color: bgSurface
                                border.color: borderColor
                                border.width: 1
                                radius: 6

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 6

                                    Text {
                                        text: "Windows"
                                        color: textPrimary
                                        font.pixelSize: 12
                                        font.family: font
                                        font.bold: true
                                    }

                                    ListView {
                                        id: windowList
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        clip: true
                                        spacing: 2
                                        model: filteredWindowEntries
                                        highlightMoveDuration: 80
                                        highlight: Rectangle {
                                            color: accentPrimary
                                            border.color: activeFocus ? accentPrimary : borderColor
                                            border.width: activeFocus ? 2 : 1
                                            radius: 4
                                        }

                                        delegate: Item {
                                            required property var modelData
                                            required property int index
                                            width: windowList.width - (windowList.scrollBar ? windowList.scrollBar.width + 4 : 0)
                                            height: 44

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 12
                                                anchors.rightMargin: 12
                                                spacing: 10

                                                // App icon
                                                Item {
                                                    width: 28
                                                    height: 28
                                                    Layout.alignment: Qt.AlignVCenter

                                                    IconImage {
                                                        anchors.fill: parent
                                                        source: Quickshell.iconPath(modelData.icon ?? "", true)
                                                        visible: (modelData.icon ?? "") !== ""
                                                    }

                                                    Text {
                                                        anchors.centerIn: parent
                                                        text: ""
                                                        color: accentPrimary
                                                        font.pixelSize: 20
                                                        font.family: iconFont
                                                        visible: (modelData.icon ?? "") === ""
                                                    }
                                                }

                                                // App info
                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    Layout.alignment: Qt.AlignVCenter
                                                    spacing: 1

                                                    Text {
                                                        text: modelData.name ?? "Application"
                                                        color: selectedIndex === index ? textPrimary : textSecondary
                                                        font.pixelSize: 13
                                                        font.family: font
                                                        font.bold: selectedIndex === index
                                                        elide: Text.ElideRight
                                                        Layout.fillWidth: true
                                                    }

                                                    Text {
                                                        text: modelData.genericName ?? modelData.comment ?? ""
                                                        color: textMuted
                                                        font.pixelSize: 11
                                                        font.family: font
                                                        elide: Text.ElideRight
                                                        visible: modelData.genericName || modelData.comment
                                                        Layout.fillWidth: true
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: false
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.selectWindow(modelData)
                                            }
                                        }

                                        ScrollBar.vertical: ScrollBar {
                                            policy: ScrollBar.AsNeeded
                                            width: 8
                                        }
                                    }
                                }

                                // Window preview
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.minimumWidth: 200
                                    color: "#111318"
                                    radius: 4
                                    clip: true

                                    // Would show window preview here
                                    Text {
                                        anchors.centerIn: parent
                                        color: "#808080"
                                        text: "Window preview"
                                        font.pixelSize: 14
                                    }
                                }
                            }
                        }

                        // Action buttons
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                height: 44
                                radius: 8
                                color: bgSurface
                                border.color: borderColor
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    color: textPrimary
                                    font.pixelSize: 13
                                    font.family: font
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "Share Window"
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 44
                                radius: 8
                                color: bgSurface
                                border.color: borderColor
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    color: textMuted
                                    font.pixelSize: 13
                                    font.family: font
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "Cancel"
                                }
                            }
                        }
                    }
                }

                // Region tab - allow selecting a region
                Item {
                    anchors.fill: parent

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text {
                            text: "Select a region of your screen to share"
                            color: textSecondary
                            font.pixelSize: 12
                            font.family: font
                            wrapMode: Text.WordWrap
                            textWidth: 280
                        }

                        // Region selection instructions
                        Rectangle {
                            Layout.fillWidth: true
                            height: 200
                            color: bgSurface
                            border.color: borderColor
                            border.width: 1
                            radius: 6

                            Text {
                                anchors.centerIn: parent
                                color: textMuted
                                font.pixelSize: 12
                                font.family: font
                                text: "Move your cursor to select a region, then press Ctrl+Return\nor use the slurp region picker"
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                height: 44
                                radius: 8
                                color: bgSurface
                                border.color: borderColor
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    color: textPrimary
                                    font.pixelSize: 13
                                    font.family: font
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "Share Region"
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 44
                                radius: 8
                                color: bgSurface
                                border.color: borderColor
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    color: textMuted
                                    font.pixelSize: 13
                                    font.family: font
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "Cancel"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Session file for saving selection
    FileView {
        id: resultFile
        path: String(Quickshell.env("QSP_RESULT_FILE") || "")
        blockWrites: true
        atomicWrites: true
        printErrors: false
    }

    // Geometry file
    FileView {
        id: geometryFile
        path: String(Quickshell.env("QSP_GEOMETRY_FILE") || "")
        blockLoading: true
        blockWrites: true
        atomicWrites: true
        printErrors: false
    }

    // Timers
    Timer {
        id: initialWindowTimer
        interval: 250
        onTriggered: {
            root.windowModelReady = true;
            root.rebuildScreens();
            root.rebuildWindows();
            root.focusCurrentTab();
        }
    }

    Timer {
        id: rebuildTimer
        interval: 250
        repeat: true
        onTriggered: {
            root.rebuildAttempts += 1;
            root.rebuildScreens();
            root.rebuildWindows();
            if (root.rebuildAttempts >= 12)
                stop();
        }
    }

    // Shortcuts
    Shortcut {
        sequences: [StandardKey.Cancel]
        onActivated: {
            root.cancel();
        }
    }

    Shortcut {
        sequence: "Ctrl+Return"
        onActivated: {
            if (root.shareEnabled())
                root.shareCurrent();
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            root.cancel();
        }
    }
}