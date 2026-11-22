pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// cyberleek.cc poll countdown + latest commit of ItsNotRexed/Leonida.
// Read-only: fetches public pages, never writes anything.
Singleton {
  id: root

  property real endsAt: 0          // unix seconds, from the poll on cyberleek.cc
  property string lastSha: ""      // newest commit hash seen so far
  property string lastCommit: "…"  // latest commit message on GitHub
  property string lastAuthor: ""
  property string commitAge: ""
  property bool ok: false

  readonly property string countdown: {
    if (endsAt <= 0) return "--:--:--";
    const left = Math.floor(endsAt - clock.date.getTime() / 1000);
    if (left <= 0) return "ended";
    const d = Math.floor(left / 86400);
    const h = Math.floor(left % 86400 / 3600);
    const m = Math.floor(left % 3600 / 60);
    const s = left % 60;
    const p = n => (n < 10 ? "0" : "") + n;
    return (d > 0 ? d + "d " : "") + p(h) + ":" + p(m) + ":" + p(s);
  }

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  Process {
    id: fetchProc
    // line 1: poll end (unix seconds); line 2: sha|date|author|first line of commit message
    command: ["sh", "-c",
      "curl -fsS -m 15 https://www.cyberleek.cc/ | grep -o 'endsAt[^0-9]*[0-9]*' | head -1 | grep -o '[0-9]*$'; " +
      "curl -fsS -m 15 'https://api.github.com/repos/ItsNotRexed/Leonida/commits?per_page=1' | " +
      "jq -r '.[0] | .sha + \"|\" + .commit.author.date + \"|\" + .commit.author.name + \"|\" + (.commit.message | split(\"\\n\")[0])'"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n").filter(l => l.trim() !== "");
        if (lines.length >= 1 && /^[0-9]+$/.test(lines[0])) root.endsAt = parseInt(lines[0]);
        if (lines.length >= 2) {
          const parts = lines[lines.length - 1].split("|");
          if (parts.length >= 4 && /^[0-9a-f]{40}$/.test(parts[0])) {
            const sha = parts[0];
            const msg = parts.slice(3).join("|");
            // notify on a new commit, but not on the first load after startup
            if (root.lastSha !== "" && sha !== root.lastSha) {
              Quickshell.execDetached(["notify-send", "-a", "Leonida", "New Leonida commit",
                parts[2] + ": " + msg]);
            }
            root.lastSha = sha;
            root.lastCommit = msg;
            root.lastAuthor = parts[2];
            const mins = Math.max(0, Math.floor((Date.now() - Date.parse(parts[1])) / 60000));
            root.commitAge = mins < 60 ? mins + "m" : mins < 1440 ? Math.floor(mins / 60) + "h" : Math.floor(mins / 1440) + "d";
          }
        }
        root.ok = true;
      }
    }
  }

  // refresh every 2 minutes (GitHub allows 60 unauthenticated calls/hour; this uses 30)
  Timer {
    interval: 120000
    running: true
    repeat: true
    onTriggered: fetchProc.running = true
  }
}
