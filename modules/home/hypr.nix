# modules/home/hypr.nix
# Hyprland configuration — symlinked to ~/.config/hypr
{ config, pkgs, ... }:
{
  xdg.configFile."hypr" = {
    source = ./dotfiles/hypr;
    force = true; # on every switch: replace whatever is at ~/.config/hypr with the managed link
    recursive = true; # copy files instead of symlinking so quickshell's theme switcher/monitor manager can persist state
  };
}
