# modules/nixos/users.nix
# Paper for who lives in the house - from configuration.nix:70
{ config, pkgs, ... }:
{
  programs.fish.enable = true;

  users.users."simon" = {
    isNormalUser = true;
    description = "Simon";
    extraGroups = [ "networkmanager" "wheel" ];
    shell = pkgs.fish;
    packages = with pkgs; [];
    # no initialPassword — the account password is set with `passwd` after
    # install, and committing a default one here is how repos leak accounts.
  };
}
