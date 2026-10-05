# modules/nixos/update.nix
# installs the `update` command (scripts/update.sh) system-wide
{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "update" (builtins.readFile ../../scripts/update.sh))
  ];
}
