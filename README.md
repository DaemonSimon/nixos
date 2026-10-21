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
    │   ├── boot.nix          # systemd-boot, plymouth, quiet console, v4l2loopback fix
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

> [!TIP]
> When an update breaks the build, check
> [Troubleshooting](#troubleshooting) first. It lists the failures that come
> from upstream packages rather than from this config, and the exact text to
> search for in the log.

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
$ sudo nix-collect-garbage --delete-older-than 14d
$ nix-store --optimise
```

The first deletes generations older than 14 days plus store paths nothing
references, so the last two weeks of rebuilds stay in the boot menu and
can still be rolled back to. The second hard-links identical files so
things like fonts are stored once. Add `--print-dead` to the first to
see what it would remove first.

Adding a package means editing `modules/home/packages.nix` or
`modules/nixos/packages.nix` and rebuilding. Attribute names come from
[search.nixos.org](https://search.nixos.org), not from guessing.

## Troubleshooting

Failures that come from an upstream package rather than from this config.
Each entry leads with the exact text to search for in the build log.

### v4l2loopback module index collision

Search the build log for:

```text
two given paths contain a conflicting subpath
```

The full error looks like this:

```text
error: pkgs.buildEnv error: two given paths contain a conflicting subpath:
  '/nix/store/...-v4l2loopback-0.15.4/lib/modules/<kernel>/modules.alias' and
  '/nix/store/...-linux-<kernel>-modules/lib/modules/<kernel>/modules.alias'
```

**Cause.** `v4l2loopback` — pulled in by `nix-citizen`, see
`modules/nixos/star-citizen.nix` — ships its own copy of the kernel's module
index (`modules.dep`, `modules.alias`, `modules.symbols`, `modules.builtin*`)
inside `lib/modules/<kernel>/`. The kernel already has files with those exact
names in that exact place, and Nix refuses to merge two different files under
one path, so `system.modulesTree` fails to build.

**Fix.** `modules/nixos/boot.nix` carries an overlay that strips `modules.*`
from the v4l2loopback output. Nothing collides, and the kernel's own index is
regenerated by `depmod` at boot — it already lists the module.

**Is it permanent?** No, and it does not need to be. This is an upstream
nixpkgs bug, not a mistake in this config. The workaround lives here until
nixpkgs stops shipping the index. If that happens the `rm` simply deletes
nothing, the build still passes, and this entry plus the overlay in
`boot.nix` can both be deleted.

> [!TIP]
> `grep -rn "v4l2loopback" /etc/nixos` finds nothing on its own — the
> package is never named in this config. It arrives through the
> `nix-citizen` flake module. To find which file pulled a package in, ask
> the evaluated config:
>
> ```console
> $ nix eval --impure --json --expr 'let f = builtins.getFlake "/etc/nixos";
>     n = f.nixosConfigurations.nixos; in
>     map (d: d.file) n.options.boot.extraModulePackages.definitionsWithLocations'
> ```
>
> ```json
> [".../modules/nixos/star-citizen.nix",".../hosts/nixos/hardware-configuration.nix",".../nixos/modules/services/networking/netbird.nix"]
> ```
