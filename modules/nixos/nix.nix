# modules/nixos/nix.nix
# Paper for Nix itself and allowing apps that are not fully free
{ config, pkgs, inputs, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Lets runtime-downloaded dynamically-linked binaries run (JREs, launchers)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [ stdenv.cc.cc zlib ];

  # Binary cache for nix-citizen (Star Citizen) - avoids rebuilding wine-astral
  nix.settings.extra-substituters = [ "https://nix-citizen.cachix.org" ];
  nix.settings.extra-trusted-public-keys = [ "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo=" ];
}
