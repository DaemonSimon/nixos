import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Scope {
  id: root
  property var theme: DefaultTheme {}
  property string font: "Hack Nerd Font"

  IpcHandler {
    target: "launcher"

    function toggle(): void {
      launcherPanel.visible = !launcherPanel.visible
      if (launcherPanel.visible) {
        searchInput.text = ""
        selectedIndex = -1
        searchInput.forceActiveFocus()
      }
    }
  }

  property int selectedIndex: 0

  // Add ids here to hide broken entries (e.g. "uuctl", "nixos-manual")
  property var hiddenIds: ["uuctl", "nixos-manual", "code-url-handler", "kitty-open", "org.quickshell", "org.freedesktop.Xwayland", "xdg-desktop-portal-gtk"]

  // Where `needle` begins a word inside `hay`, else -1. Word-start matching is
  // what stops "file" from matching "Profile" via "pro-file".
  function wordStart(hay, needle) {
    const escaped = needle.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const m = new RegExp("(^|[^a-z0-9])" + escaped).exec(hay);
    return m === null ? -1 : m.index + (m[0].length - escaped.length);
  }

  // First letter of each word: "yazi file manager" -> "yfm".
  function initials(hay) {
    return (hay.match(/(^|[^a-z0-9])([a-z0-9])/g) || []).map(w => w[w.length - 1]).join("");
  }

  // Index of the first character of the subsequence `needle` within `hay`, or
  // -1 when it is not a subsequence at all. This is what makes "fc"-style
  // queries hit something instead of nothing.
  function fuzzyMatch(needle, hay) {
    let cursor = 0, first = -1;
    for (const ch of needle) {
      const at = hay.indexOf(ch, cursor);
      if (at === -1) return -1;
      if (first === -1) first = at;
      cursor = at + 1;
    }
    return first;
  }

  // Rank one desktop entry against the query. Lower tier wins.
  //
  // The .desktop data was never wrong: vesktop.desktop already ships
  // Keywords=discord;vencord;electron;chat. The old scorer threw that away by
  // ranking Comment (3) above Keywords (4), so "disco" matched Prism
  // Launcher's "Discover, manage, and play Minecraft instances" in the same
  // tier as Vesktop - and the alphabetical tiebreak then picked Prism.
  //
  // Keywords now outrank prose comments: keywords are author-curated search
  // aliases, comments are English sentences and collide constantly.
  function rankApp(d, q) {
    const name = (d.name || "").toLowerCase();
    const generic = (d.genericName || "").toLowerCase();
    const comment = (d.comment || "").toLowerCase();
    const keywords = (d.keywords || []).map(k => k.toLowerCase());

    let best = null;
    const offer = (tier, position) => {
      if (best === null || tier < best.tier || (tier === best.tier && position < best.position))
        best = { tier, position };
    };

    if (name === q) offer(0, 0);
    if (name.startsWith(q)) offer(1, 0);
    if (root.initials(name).startsWith(q)) offer(2, 0);
    const word = root.wordStart(name, q);
    if (word !== -1) offer(3, word);
    if (name.includes(q)) offer(4, name.indexOf(q));
    const fuzzyAt = root.fuzzyMatch(q, name);
    if (fuzzyAt !== -1) offer(5, fuzzyAt);
    if (keywords.some(k => k === q)) offer(6, 0);
    const kw = keywords.findIndex(k => k.includes(q));
    if (kw !== -1) offer(7, kw);
    if (generic.includes(q)) offer(8, generic.indexOf(q));
    if (comment.includes(q)) offer(9, comment.indexOf(q));
    return best;
  }

  ScriptModel {
    id: filteredApps
    objectProp: "id"
    values: {
      // filter out hidden/broken entries before searching
      const all = [...DesktopEntries.applications.values].filter(d => {
        if (d.noDisplay) return false;
        if (!d.execString || d.execString.trim() === "") return false;
        if (hiddenIds.includes(d.id)) return false;
        return true;
      });
      const q = searchInput.text.trim().toLowerCase();
      if (q === "") return all.sort((a, b) => a.name.localeCompare(b.name));
      const scored = [];
      for (const d of all) {
        const rank = root.rankApp(d, q);
        if (rank !== null) scored.push({ d, rank });
      }
      // Best rank first. Deliberately NOT alphabetical first - that is exactly
      // what made "Prism Launcher" beat "Vesktop" for the query "disco".
      // Ties fall back to match position, then name, so initialism hits ("yfm"
      // for Yazi File Manager) rank above a stray comment match.
      scored.sort((a, b) => {
        if (a.rank.tier !== b.rank.tier) return a.rank.tier - b.rank.tier;
        if (a.rank.position !== b.rank.position) return a.rank.position - b.rank.position;
        return a.d.name.localeCompare(b.d.name);
      });
      return scored.map(x => x.d);
    }
  }

  function launchApp(entry) {
    entry.execute();
    launcherPanel.visible = false;
  }

  PanelWindow {
    id: launcherPanel
    visible: false
    focusable: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "quickshell-launcher"

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
      onClicked: launcherPanel.visible = false

      Rectangle {
        anchors.fill: parent
        color: root.theme.bgOverlay
      }
    }

    // Centered launcher box
    Rectangle {
      id: launcherBox
      anchors.centerIn: parent
      width: 580
      height: 480
      radius: 16
      color: root.theme.bgBase
      border.color: root.theme.bgBorder
      border.width: 1

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        Text {
          text: "  Applications"
          color: root.theme.accentPrimary
          font.pixelSize: 14
          font.family: root.font
          font.bold: true
        }

        // Search bar
        Rectangle {
          Layout.fillWidth: true
          height: 44
          radius: 10
          color: root.theme.bgSurface
          border.color: searchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
          border.width: 1

          Behavior on border.color {
            ColorAnimation { duration: 150 }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10

            Text {
              text: ""
              color: root.theme.textMuted
              font.pixelSize: 16
              font.family: root.font
              Layout.alignment: Qt.AlignVCenter
            }

            TextInput {
              id: searchInput
              Layout.fillWidth: true
              Layout.alignment: Qt.AlignVCenter
              color: root.theme.textPrimary
              font.pixelSize: 15
              font.family: root.font
              clip: true
              focus: true
              Accessible.role: Accessible.EditableText
              Accessible.name: "Search applications"

              Text {
                anchors.fill: parent
                text: "Type to search..."
                color: root.theme.textMuted
                font: parent.font
                visible: !parent.text && !parent.activeFocus
                verticalAlignment: Text.AlignVCenter
              }

              onTextChanged: root.selectedIndex = text === "" ? -1 : 0

              Keys.onEscapePressed: launcherPanel.visible = false

              Keys.onPressed: event => {
                if (event.key === Qt.Key_Down) {
                  event.accepted = true;
                  root.selectedIndex = Math.min(root.selectedIndex + 1, resultsList.count - 1);
                  resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                } else if (event.key === Qt.Key_Up) {
                  event.accepted = true;
                  root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                  resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                  event.accepted = true;
                  if (root.selectedIndex >= 0) {
                    const entry = filteredApps.values[root.selectedIndex];
                    if (entry) root.launchApp(entry);
                  }
                } else if (event.key === Qt.Key_Tab) {
                  event.accepted = true;
                  root.selectedIndex = Math.min(root.selectedIndex + 1, resultsList.count - 1);
                  resultsList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                }
              }
            }
          }
        }

        // Results count
        Text {
          text: resultsList.count + " application" + (resultsList.count !== 1 ? "s" : "")
          color: root.theme.textMuted
          font.pixelSize: 11
          font.family: root.font
        }

        // App list
        ListView {
          id: resultsList
          Layout.fillWidth: true
          Layout.fillHeight: true
          model: filteredApps
          clip: true
          spacing: 2
          boundsBehavior: Flickable.StopAtBounds
          currentIndex: root.selectedIndex
          highlightMoveDuration: 150
          highlightMoveVelocity: -1

          highlight: Rectangle {
            radius: 8
            color: root.theme.bgSelected
            visible: root.selectedIndex >= 0

            Rectangle {
              width: 3
              height: 24
              radius: 2
              color: root.theme.accentPrimary
              anchors.left: parent.left
              anchors.leftMargin: 2
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          delegate: Rectangle {
            id: delegateRoot
            required property var modelData
            required property int index

            Accessible.role: Accessible.Button
            Accessible.name: (modelData.name ?? "Application") + (modelData.genericName ? " - " + modelData.genericName : "")

            width: resultsList.width
            height: 44
            radius: 8
            color: "transparent"

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              spacing: 12

              // App icon
              Item {
                width: 28
                height: 28
                Layout.alignment: Qt.AlignVCenter

                IconImage {
                  anchors.fill: parent
                  source: Quickshell.iconPath(delegateRoot.modelData.icon ?? "", true)
                  visible: (delegateRoot.modelData.icon ?? "") !== ""
                }

                // Fallback icon
                Text {
                  anchors.centerIn: parent
                  text: ""
                  color: root.theme.accentPrimary
                  font.pixelSize: 20
                  font.family: root.font
                  visible: (delegateRoot.modelData.icon ?? "") === ""
                }
              }

              // App info
              ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                Text {
                  text: delegateRoot.modelData.name ?? ""
                  color: root.selectedIndex === delegateRoot.index ? root.theme.textPrimary : root.theme.textSecondary
                  font.pixelSize: 13
                  font.family: root.font
                  font.bold: root.selectedIndex === delegateRoot.index
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }

                Text {
                  text: delegateRoot.modelData.genericName ?? delegateRoot.modelData.comment ?? ""
                  color: root.theme.textMuted
                  font.pixelSize: 11
                  font.family: root.font
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                  visible: text !== ""
                }
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: false
              cursorShape: Qt.PointingHandCursor
              onClicked: root.launchApp(delegateRoot.modelData)
            }
          }

          // Empty state
          Text {
            anchors.centerIn: parent
            text: "  No applications found"
            color: root.theme.textMuted
            font.pixelSize: 14
            font.family: root.font
            visible: resultsList.count === 0 && searchInput.text !== ""
          }
        }

        // Footer hint
        RowLayout {
          Layout.fillWidth: true
          spacing: 16

          Row {
            spacing: 4
            Rectangle {
              width: hintUp.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
              Text { id: hintUp; anchors.centerIn: parent; text: "↑↓"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font }
            }
            Text { text: "navigate"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
          }

          Row {
            spacing: 4
            Rectangle {
              width: hintEnter.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
              Text { id: hintEnter; anchors.centerIn: parent; text: "⏎"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font }
            }
            Text { text: "launch"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
          }

          Row {
            spacing: 4
            Rectangle {
              width: hintEsc.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
              Text { id: hintEsc; anchors.centerIn: parent; text: "esc"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font }
            }
            Text { text: "close"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
          }

          Item { Layout.fillWidth: true }
        }
      }
    }
  }
}
