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