# modules/home/lazyvim.nix
# Paper for neovim + LazyVim, fully declarative via lazyvim-nix
# All LazyVim plugins come from the nix store - no cloning, no manual setup.
# Update later with: nix flake update lazyvim-nix && sudo nixos-rebuild switch --flake .#nixos
{ config, pkgs, inputs, ... }:
{
  imports = [ inputs.lazyvim-nix.homeManagerModules.default ];

  programs.lazyvim = {
    enable = true;

    # Language extras (disable until needed)
    extras = {
      # lang.nix.enable = true;
    };
  };

  # neovim is removed from home.packages - this module now owns it
  programs.neovim.defaultEditor = true; # sets EDITOR/VISUAL

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}