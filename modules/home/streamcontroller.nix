# modules/home/streamcontroller.nix
# StreamController plugins for YOUR room (Discord deafen toggle via Vesktop IPC)
{ config, pkgs, ... }:

{
  # The flatpak only grants filesystem access to ~/.var/app/..., so the
  # /nix/store symlinks home-manager creates are unreadable inside the
  # sandbox. This override adds read access to /nix/store, which makes
  # the plugin (symlinked below) load.
  home.file.".local/share/flatpak/overrides/com.core447.StreamController" = {
    text = ''
      [Context]
      filesystems=home;/nix/store;
    '';
  };

  home.file.".var/app/com.core447.StreamController/data/plugins/discord_deafen" = {
    source = ./dotfiles/streamcontroller/discord_deafen;
    recursive = true;
  };
}
