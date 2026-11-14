# modules/nixos/nix.nix
# Paper for Nix itself and allowing apps that are not fully free
{ config, pkgs, inputs, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Workaround: nixpkgs' Rust setup hook always exports
  # RUSTONIG_SYSTEM_LIBONIG=1, but the `code` package (just-every coding CLI)
  # forgot to add oniguruma, so onig_sys fails its pkg-config probe. Add it
  # here until the package is fixed upstream; the overlay also reaches
  # home-manager because it uses the global pkgs (useGlobalPkgs = true).
  nixpkgs.overlays = [
    (final: prev: {
      code = prev.code.overrideAttrs (old: {
        buildInputs = (old.buildInputs or [ ]) ++ [ final.oniguruma ];
      });
    })
  ];

  # Lets runtime-downloaded dynamically-linked binaries run (JREs, launchers)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [ stdenv.cc.cc zlib ];

  # Binary cache for nix-citizen (Star Citizen) - avoids rebuilding wine-astral
  nix.settings.extra-substituters = [ "https://nix-citizen.cachix.org" ];
  nix.settings.extra-trusted-public-keys = [ "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo=" ];
}
