# modules/home/mime-defaults.nix
# Ensures Yazi is the default file manager (opens directories instead of VS Code).
# This survives complete NixOS reinstalls since it's part of the config.
{ config, pkgs, ... }:
{
  programs.home-manager.users.simon.options = ''
    [mimeapps]
    inode/directory=yazi.desktop
  '';
}