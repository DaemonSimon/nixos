# Vesktop bridge

The StreamController actions talk to a tiny HTTP server that runs **inside
Vesktop's main process**. It is not a Vencord plugin; it is a few lines
appended to a copy of Vesktop's `vencordDesktopMain.js`, which Vesktop loads
with `require()` (so Node's `http` and `electron` modules are available).

It clicks Discord's own mute/deafen buttons, which means Discord performs the
action and sends it to its servers - the change is visible to everyone in the
call, not just muted locally.

## Install / update

```bash
./install-bridge.sh
```

This copies Vesktop's Vencord bundle into `~/.config/vesktop/vencord-custom/`
and appends `vencord-bridge.js`. Afterwards point Vesktop at that directory
once (Settings -> Vencord Location) and restart it.

Re-run the script after every Vesktop/Vencord update to re-apply the bridge to
the new bundle.

## Endpoints

Bound to `127.0.0.1:6459` (loopback only):

| Endpoint     | Effect                                        |
|--------------|-----------------------------------------------|
| `GET /ping`  | returns `pong` when the bridge is alive       |
| `GET /mute`  | toggles mute, returns the clicked button name |
| `GET /deafen`| toggles deafen, returns the clicked button name |

```bash
curl http://127.0.0.1:6459/ping
```

## Caveats

- Mute and deafen can only be toggled while Vesktop is running with the bridge;
  otherwise the action logs `Vesktop bridge is not reachable`.
- The endpoint is unauthenticated but loopback-only, so only local processes can
  reach it.
