# modules/home/quickshell.nix
# Quickshell desktop shell — symlinked to ~/.config/quickshell
{ config, pkgs, ... }:
{
  xdg.configFile."quickshell" = {
    source = ./dotfiles/quickshell;
    force = true; # on every switch: replace whatever is at ~/.config/quickshell with the managed link
    recursive = true; # copy files instead of symlinking so the shell can persist theme/wallpaper state
  };
}