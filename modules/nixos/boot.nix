# modules/nixos/boot.nix
# Paper for how the house starts - the boot loader
{ config, pkgs, ... }:
{
  # Use the systemd-boot EFI boot loader - from configuration.nix:29
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Don't sit on the text boot menu - jump straight in (5s default).
  boot.loader.timeout = 0;

  # ── Plymouth splash screen ──────────────────────────────
  # This alone adds the "splash" kernel param and injects
  # Plymouth into the initrd automatically.
  boot.plymouth.enable = true;
  boot.plymouth.theme = "bgrt";     # firmware/Windows-style logo (NixOS snowflake)
  # boot.plymouth.theme = "breeze"; # alternative: animated spinner
  # boot.plymouth.logo = /path/to/logo.png; # optional custom logo

  # ── v4l2loopback kernel module ─────────────────────────
  # nix-citizen (modules/nixos/star-citizen.nix) puts v4l2loopback into
  # boot.extraModulePackages. The nixpkgs package ships its own depmod
  # index - modules.dep, modules.alias, modules.symbols, modules.builtin*
  # - inside lib/modules/<version>/, which is exactly where the kernel's
  # own "modules" output keeps its index. Merging the two into
  # system.modulesTree then fails with a "collision between ..." error.
  #
  # Dropping the pre-generated index is safe: depmod rebuilds the real
  # index for the merged tree at boot.
  nixpkgs.overlays = [
    (final: prev: {
      linuxPackages = prev.linuxPackages.extend (self: super: {
        v4l2loopback = super.v4l2loopback.overrideAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            rm -f $out/lib/modules/*/modules.*
          '';
        });
      });
    })
  ];

  # ── Silent kernel console ───────────────────────────────
  boot.consoleLogLevel = 0;                    # -> loglevel=0, emergencies only
  boot.kernelParams = [ "quiet" "udev.log_level=3" ];

  # ── Silent stage-2 systemd (hides "Starting/OK" lines;
  #    journald still captures logs, so nothing is lost) ──
  systemd.settings.Manager.ShowStatus = false;

  # ── Silent initrd systemd (you use the systemd initrd) ──
  boot.initrd.systemd.settings.Manager.ShowStatus = false;

  # Note: initrd.systemd.extraConfig / systemd.extraConfig were
  # removed in modern nixpkgs; settings.Manager replaces them.
  # boot.initrd.verbose = false only affects the deprecated
  # scripted initrd, so it's a no-op here.
}