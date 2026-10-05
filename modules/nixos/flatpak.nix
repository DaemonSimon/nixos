# modules/nixos/flatpak.nix
# Flatpak daemon + declarative app management (via the nix-flatpak module)
#
# Apps live outside the Nix store, so this is "convergent" management:
# declared apps get installed/updated on every activation, and anything
# removed from `packages` gets pruned. A fresh reinstall restores them.
{ ... }:

{
  services.flatpak = {
    # Provides the flatpak CLI/daemon, fuse3, the flatpak system user,
    # and puts /var/lib/flatpak/exports on the session profile.
    # Requires xdg.portal.enable = true (already set in portals.nix).
    enable = true;

    # Explicit remote list. nix-flatpak's default is just flathub, but
    # declaring it here makes the config self-documenting.
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    packages = [
      # Modrinth App - Minecraft launcher / modpack manager.
      # Previously the nixpkgs `modrinth-app` package; switched to Flatpak
      # because the Nix build had no working loader-version picker.
      {
        appId = "com.modrinth.ModrinthApp";
        origin = "flathub";
      }
    ];
  };
}
