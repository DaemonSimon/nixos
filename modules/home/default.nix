# modules/home/default.nix
# This box loads all YOUR ROOM papers
{ config, pkgs, ... }:
{
  imports = [
     ./packages.nix
     ./yazi.nix
     ./firefox.nix
     ./cursor.nix
     ./hypr.nix
    ./hyprshot.nix
    ./quickshell.nix
    ./shell.nix
    ./fish.nix
    ./kitty.nix
     ./lazyvim.nix
     ./streamcontroller.nix
  ];

  # Your name and where your room is - MUST match users.users.simon in nixos/users.nix
  home.username = "simon";
  home.homeDirectory = "/home/simon";
  home.stateVersion = "26.05"; # same as system.stateVersion

  # Let home-manager manage itself
  programs.home-manager.enable = true;
}
