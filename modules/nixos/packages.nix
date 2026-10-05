# modules/nixos/packages.nix
# Paper for programs that belong to the HOUSE (everyone can use)
# Your personal programs moved to modules/home/packages.nix
# Keep only tiny system tools here if you want.
{ config, pkgs, inputs, ... }:
{
  # Example: keep git for emergency if your room helper breaks
  environment.systemPackages = with pkgs; [
    git
    # if you do NOT want home-manager yet, uncomment the list below:
    # vesktop localsend kitty firefox vscode neovim ripgrep fd gcc gnumake unzip opencode fuzzel
  ];
}
