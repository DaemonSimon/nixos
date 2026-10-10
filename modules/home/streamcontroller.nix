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
    plugin_source="${pluginSource}"
    plugin_dir="${pluginDir}"

    tree_checksum() {
      ( cd "$1" && find . -type f ! -path '*/__pycache__/*' -exec cksum {} + | sort ) | cksum
    }

    # Only touch the plugin tree when it differs from the source. Replacing it
    # while StreamController is running makes the live app drop the plugin.
    if [ ! -d "$plugin_dir" ] || [ "$(tree_checksum "$plugin_dir")" != "$(tree_checksum "$plugin_source")" ]; then
      run rm -rf "$plugin_dir"
      run mkdir -p "$plugin_dir"
      run cp -r "$plugin_source/." "$plugin_dir/"
      run chmod -R u+w "$plugin_dir"
    fi
  '';
}
