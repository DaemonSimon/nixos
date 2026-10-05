# modules/home/cursor.nix
# Your mouse pointer — the macOS cursors, at 32px.
#
# apple-cursor ships exactly two right-handed XCursor themes, "macOS" (the
# classic black-outlined arrow, for light backgrounds) and "macOS-White" (for
# dark backgrounds). Both land on XCURSOR_PATH via the home-manager profile's
# share/icons symlink farm, so the quickshell theme switcher can pick between
# them at runtime without a rebuild — see
# dotfiles/quickshell/theme-switcher/cursor-theme.sh.
#
# Note: apple-cursor is `unfree` in nixpkgs ("potentially a derivative work of
# copyrighted Apple designs"), which is why meta.available is false. This
# machine already sets nixpkgs.config.allowUnfree = true, so it builds as-is.
{ config, pkgs, ... }:

{
  # gsettings-desktop-schemas exposes org.gnome.desktop.interface, which is what
  # GTK, Electron and Hyprland's cursor:sync_gsettings_theme actually read.
  # glib provides the gsettings CLI used by the theme switcher's colour-scheme
  # sync. Both were missing, so neither worked.
  home.packages = [
    pkgs.glib
    pkgs.gsettings-desktop-schemas
  ];

  home.pointerCursor = {
    enable = true; # stated explicitly to avoid home-manager's implicit-set warning
    package = pkgs.apple-cursor; # 2.0.1
    name = "macOS";
    size = 32;

    # ~/.icons/<name>, for apps that ignore the XDG data dir (Wine/Proton).
    dotIcons.enable = true;

    # Deliberately NOT enabled:
    #   x11       - only emits an `xsetroot` line into xsession.profileExtra,
    #               which never runs under Hyprland/UWSM.
    #   gtk       - needs a separate gtk.enable and would make home-manager
    #               own ~/.config/gtk-3.0/settings.ini; dconf below is the
    #               path GTK4/Electron/Hyprland read.
    #   hyprcursor - defaults to false, and hypr settings/appearance.lua sets
    #               cursor.enable_hyprcursor = false to force XCursor.
  };

  dconf.settings."org/gnome/desktop/interface" = {
    cursor-theme = config.home.pointerCursor.name;
    cursor-size = config.home.pointerCursor.size; # schema type "i", so a plain int
  };

  # home.pointerCursor only sets home.sessionVariables, which Home Manager
  # exports into the *shell* session. Graphical apps don't read that — they
  # inherit the systemd user environment, which comes from
  # systemd.user.sessionVariables (written to ~/.config/environment.d). Without
  # this, nothing tells GTK/Electron/Wine that the cursor theme exists.
  systemd.user.sessionVariables = {
    XCURSOR_THEME = config.home.pointerCursor.name;
    XCURSOR_SIZE = toString config.home.pointerCursor.size;
  };
}
