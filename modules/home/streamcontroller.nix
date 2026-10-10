# modules/home/streamcontroller.nix
# StreamController plugins for YOUR room (Discord deafen toggle via Vesktop IPC)
{ config, pkgs, ... }:

{
  home.file.".var/app/com.core447.StreamController/data/plugins/discord-deafen" = {
    source = ./dotfiles/streamcontroller/discord-deafen;
    recursive = true;
  };
}
