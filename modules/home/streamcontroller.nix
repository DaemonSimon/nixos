# modules/home/streamcontroller.nix
#
# Installs the "Discord Deafen" StreamController plugin.
#
# StreamController runs as a Flatpak whose sandbox cannot read the Nix store,
# so the plugin cannot simply be symlinked in like most home-manager files.
# Instead we copy it into the app's data directory on every activation. That
# directory is shared by the Flatpak and the Nix build of StreamController.
{ lib, ... }:

let
  pluginId = "com_simon_DiscordDeafen";
  pluginSource = ./dotfiles/streamcontroller/discord-deafen;
  pluginDir = "$HOME/.var/app/com.core447.StreamController/data/plugins/${pluginId}";
in
{
  home.activation.installDiscordDeafenPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run rm -rf "${pluginDir}"
    run mkdir -p "${pluginDir}"
    run cp -r ${pluginSource}/. "${pluginDir}/"
    run chmod -R u+w "${pluginDir}"
  '';
}
