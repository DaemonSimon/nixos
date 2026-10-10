/* Vesktop control bridge.
 *
 * Appended to a copy of Vesktop's `vencordDesktopMain.js` (which Vesktop
 * loads with `require()`), this starts a tiny HTTP server inside Vesktop's
 * main process. The endpoints click Discord's own mute/deafen buttons, so the
 * change is sent to Discord and is visible to everyone in the call.
 *
 * Endpoints (bound to 127.0.0.1:6459):
 *   GET /ping    -> "pong"
 *   GET /mute    -> toggles mute,   returns the button label that was clicked
 *   GET /deafen  -> toggles deafen, returns the button label that was clicked
 */
try {
  const { BrowserWindow } = require("electron");
  const http = require("http");

  const PORT = 6459;

  const click = async labels => {
    const win = BrowserWindow.getAllWindows().find(
      w => w.webContents && !w.webContents.isDestroyed()
    );
    if (!win) return "no-window";

    return win.webContents.executeJavaScript(
      `(() => {
        const labels = ${JSON.stringify(labels)};
        for (const label of labels) {
          const button = document.querySelector('button[aria-label="' + label + '"]');
          if (button) { button.click(); return label; }
        }
        return null;
      })()`,
      true
    );
  };

  const server = http.createServer(async (req, res) => {
    const path = (req.url || "/").split("?")[0];
    let out = "ok";

    try {
      if (path === "/ping") out = "pong";
      else if (path === "/mute") out = await click(["Mute", "Unmute"]);
      else if (path === "/deafen") out = await click(["Deafen", "Undeafen"]);
      else {
        res.writeHead(404);
        return res.end("not found");
      }
    } catch (error) {
      res.writeHead(500);
      return res.end(String(error));
    }

    res.writeHead(200, { "Content-Type": "text/plain" });
    res.end(String(out));
  });

  server.on("error", error => console.error("[vc-bridge] server error", error));
  server.listen(PORT, "127.0.0.1", () =>
    console.log(`[vc-bridge] listening on 127.0.0.1:${PORT}`)
  );
} catch (error) {
  console.error("[vc-bridge] failed to start", error);
}
