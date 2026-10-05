# modules/nixos/packages.nix
# Paper for programs that belong to the HOUSE (everyone can use)
# Your personal programs moved to modules/home/packages.nix
# Keep only tiny system tools here if you want.
{ config, pkgs, inputs, ... }:
{
  # Example: keep git for emergency if your room helper breaks
  environment.systemPackages = with pkgs; [
    git
    # gh must live here, not in home packages: update.sh pins PATH to
    # /run/current-system/sw/bin and its git push relies on `gh` as the
    # credential helper. Home packages would land outside that PATH.
    gh
    # if you do NOT want home-manager yet, uncomment the list below:
    # vesktop localsend kitty firefox vscode neovim ripgrep fd gcc gnumake unzip opencode fuzzel
  ];
}
