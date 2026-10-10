# modules/nixos/services.nix
# Paper for extra house helpers
{ config, pkgs, ... }:
{
  services.flatpak.enable = true;

  services.duplicati = {
    enable = true;
    interface = "0.0.0.0";
    port = 8200;
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="0fd9", MODE="0666", GROUP="plugdev"
  '';
}
