# modules/home/hyprshot.nix
# Patched hyprshot — keeps your screenshot keybinds clean.
# Fixes:
#  1. `grim -c` -> include cursor (mouse stays visible)
#  2. cancel guard -> ESC / no region = no screenshot (no constant full-screen shot)
# The hover-tooltip freeze is handled via keybinds ` --freeze` in dotfiles/hypr/settings/keybinds.lua
{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    (hyprshot.overrideAttrs (oldAttrs: {
      postPatch = (oldAttrs.postPatch or "") + ''
        substituteInPlace hyprshot \
          --replace-fail 'grim -g' 'grim -c -g'
        substituteInPlace hyprshot \
          --replace-fail '    save_geometry "''${geometry}"' '    if [ -z "''${geometry}" ]; then echo "No region selected, cancelled" >&2; exit 0; fi
        save_geometry "''${geometry}"'
        substituteInPlace hyprshot \
          --replace-fail 'function save_geometry() {' 'function save_geometry() {
    if [ -z "$1" ]; then echo "No geometry, cancelled" >&2; exit 0; fi'
      '';
    }))
  ];
}
