# modules/home/streamcontroller.nix
# StreamController plugins for YOUR room (Discord deafen toggle via Vesktop IPC)
{ config, pkgs, ... }:

{
  home.file."StreamController/plugins/discord-deafen" = {
    source = ./dotfiles/streamcontroller/discord-deafen;
    recursive = true;
  };
}
