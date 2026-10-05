# modules/nixos/desktop.nix
# Paper for what you see on the screen
{ config, pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.uwsm.enable = true;

  services.greetd.enable = true;
  services.displayManager.regreet.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
}
