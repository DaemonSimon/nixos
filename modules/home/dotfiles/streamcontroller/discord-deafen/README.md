# Discord Deafen (StreamController)

Mute and deafen Discord from your StreamController deck.

The plugin does **not** use Discord's IPC socket (which Vesktop does not
implement for voice settings). Instead it talks to a small local HTTP bridge
that runs inside Vesktop and clicks Discord's own mute/deafen buttons. Because
Discord performs the action, the change is sent to Discord's servers and is
visible to everyone in the call.

## Requirements

- Vesktop with the bridge installed (see `vesktop/`).
- The bridge listens on `127.0.0.1:6459` inside Vesktop's main process.

## Actions

- **Discord Deafen** - toggles deafen.
- **Discord Mute** - toggles mute.

The bottom label shows `Deafen`/`Mute` while the bridge is reachable and
`No bridge` when Vesktop is not running (or the bridge is not installed).

## Installation

The plugin is installed declaratively by `modules/home/streamcontroller.nix`
into `~/.var/app/com.core447.StreamController/data/plugins/`
(the data directory shared by both the Flatpak and the Nix build).

## Vesktop bridge

See `vesktop/README.md`.
