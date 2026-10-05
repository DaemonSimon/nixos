# modules/nixos/xremap.nix
# Paper for remapping keys below the compositor
{ config, pkgs, ... }:
{
  services.xremap = {
    enable = true;

    # Hyprland is a wlroots-based compositor
    withWlroots = true;

    # App-specific remaps are only implemented for wlroots in user mode
    serviceMode = "user";
    userName = "simon";

    config = {
      keymap = [
        {
          name = "Firefox URL Dropdown";
          application = {
            # Matches the Hyprland window class
            only = "firefox";
          };
          remap = {
            # KEY_GRAVE is the evdev name for the physical key located at XKB code 49
            "GRAVE" = "C-l";
          };
        }
      ];
    };
  };

}
