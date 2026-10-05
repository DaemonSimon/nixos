# modules/nixos/star-citizen.nix
# Paper for Star Citizen - RSI Launcher via nix-citizen
# Uses the upstream NixOS module (package + sysctl, limits, udev, ntsync).
# Docs: https://github.com/LovingMelody/nix-citizen
{ inputs, ... }:
{
  imports = [ inputs.nix-citizen.nixosModules.default ];

  programs.rsi-launcher = {
    enable = true;
    # Defaults kept on purpose:
    # setLimits (vm.max_map_count, fs.file-max, nofile), udevRules (joysticks),
    # enableNTsync (auto on kernel >= 6.14), includeOverlay, wine-astral backend.
    # Uncomment only what you need:
    # umu.enable = false;
    # patchXwayland = false;
    # location = "$HOME/Games/rsi-launcher";
  };
}
