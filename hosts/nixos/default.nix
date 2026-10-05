# hosts/nixos/default.nix
# This is the front door of your house.
# It says: "I am house nixos" and lists which boxes to load.
{ config, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos
  ];

  # Host name - same as before: networking.hostName = "nixos"
  networking.hostName = "nixos";

  hardware.bluetooth.enable = true;

  # Do NOT change this - from configuration.nix:157
  system.stateVersion = "26.05";
}
