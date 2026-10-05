# NixOS config

My NixOS configuration for a single laptop. Home Manager runs as a NixOS
module, so one rebuild covers both the system and everything in my home
directory.

## Overview

| Component | |
| --- | --- |
| NixOS release | 26.11, tracking `nixos-unstable` |
| Kernel | nixpkgs default |
| Boot | systemd-boot, Plymouth splash |
| Compositor | Hyprland (Wayland) |
| Desktop shell | quickshell — bar, notifications, wallpaper, OSD, monitor manager |
| Shell | fish |
| Terminal | kitty |
| Editor | LazyVim via `lazyvim-nix` |
| File manager | yazi |
| Git TUI | lazygit |
| Browser | firefox |
| Key remapping | xremap, under Hyprland |
| Flatpak apps | Modrinth App |
| Backups | duplicati, port 8200 |
| Remote access | tailscale |
| Gaming | RSI Launcher via `nix-citizen` |

## Structure

```
.
├── flake.nix               # inputs and the single nixosConfiguration
├── flake.lock              # pinned revisions — `nix flake update` moves this
├── hosts
│   └── nixos
│       ├── default.nix               # imports the hardware config + modules/nixos
│       └── hardware-configuration.nix # generated, don't hand-edit
└── modules
    ├── nixos                 # imported by hosts/nixos/default.nix
    │   ├── default.nix       # import list for the system side
    │   ├── audio.nix         # pipewire
    │   ├── boot.nix          # systemd-boot, plymouth, quiet console
    │   ├── desktop.nix       # hyprland, uwsm, greetd
    │   ├── flatpak.nix       # daemon + declarative flatpak apps
    │   ├── locale.nix        # timezone, locale, keymap
    │   ├── networking.nix    # networkmanager, tailscale
    │   ├── nix.nix           # flakes, unfree, nix-ld, substituters
    │   ├── packages.nix      # environment.systemPackages
    │   ├── services.nix      # duplicati
    │   ├── star-citizen.nix  # rsi-launcher module
    │   ├── users.nix         # simon, wheel + networkmanager
    │   └── xremap.nix        # evdev-level remaps
    └── home                  # imported by flake.nix, for user simon
        ├── default.nix       # import list for the home side
        ├── cursor.nix        # macOS cursors
        ├── firefox.nix       # profile + preferences
        ├── fish.nix          # abbreviations
        ├── hypr.nix          # links dotfiles/hypr -> ~/.config/hypr
        ├── hyprshot.nix      # patched screenshot tool
        ├── kitty.nix
        ├── lazyvim.nix       # neovim + LazyVim
        ├── packages.nix      # home.packages
        ├── quickshell.nix    # links dotfiles/quickshell -> ~/.config
        ├── shell.nix
        ├── yazi.nix
        └── dotfiles/
            ├── firefox/      # userChrome.css, userContent.css
            ├── hypr/         # hyprland.lua, settings/, scripts/, scheme/
            └── quickshell/   # QML shell: bar, notifications, wallpaper, osd
```

`flake.nix` wires up xremap, nix-flatpak and home-manager, and passes the
inputs down through `specialArgs` so any module can read `inputs.*`.

## Applying changes

```console
$ cd /etc/nixos
$ sudo nixos-rebuild dry-build --flake .#nixos
$ sudo nixos-rebuild switch --flake .#nixos
```

`dry-build` evaluates and builds without touching the running system.
`switch` activates the result and sets it as the systemd-boot default.
`boot` records it for the next reboot without activating it, which is what
you want when the change is to the bootloader or initrd.

## Updating

```console
$ nix flake update
$ sudo nixos-rebuild dry-build --flake .#nixos
$ sudo nixos-rebuild switch --flake .#nixos
```

`nix flake update` does not need sudo — `flake.lock` belongs to `simon` and
sits in `/etc/nixos`. The rebuild does. Since nixpkgs tracks
`nixos-unstable`, the jump is often large enough to break a build, so
`dry-build` earns its place between the two.

To move a single input:

```console
$ nix flake update nixpkgs
$ nix flake update nixpkgs home-manager
```

> [!NOTE]
> `quickshell` in `flake.nix` is the one input with no ref pinned, so
> `nix flake update` always takes whatever its branch points at that day.
> It is the desktop shell and the most likely input to break a build.

## Generations

```console
$ sudo nixos-rebuild list-generations
$ sudo nixos-rebuild switch --rollback
```

Every `switch` keeps the previous system intact, so a bad rebuild is one
command away from undone. Older generations can also be picked from the
boot menu.

> [!WARNING]
> `boot.loader.timeout = 0` in `modules/nixos/boot.nix` hides that menu.
> Hold an arrow key during boot to reach it, or it flashes past and you
> land on the newest generation.

## Moving to a new disk

`hosts/nixos/hardware-configuration.nix` holds the root and EFI UUIDs taken
from the original install. On a different drive those names do not exist and
the machine stops at `device not found`. It has happened here once: the
file pointed at a previous disk until 2026-09-19, and its header comment
records the values that were replaced.

From an installer, with the new root mounted at `/mnt`:

```console
$ nixos-generate-config --root /mnt
$ cp /mnt/etc/nixos/hardware-configuration.nix /etc/nixos/hosts/nixos/
$ nixos-install --flake /etc/nixos#nixos
```

The password for `simon` is set during that install, not here.

## Maintenance

```console
$ sudo nix-collect-garbage -d
$ nix-store --optimise
```

The first deletes store paths nothing references, including generations
older than you want to keep. The second hard-links identical files so
things like fonts are stored once. Add `--print-dead` to the first to see
what it would remove first.

Adding a package means editing `modules/home/packages.nix` or
`modules/nixos/packages.nix` and rebuilding. Attribute names come from
[search.nixos.org](https://search.nixos.org), not from guessing.
