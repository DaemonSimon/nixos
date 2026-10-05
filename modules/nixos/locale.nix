# modules/nixos/locale.nix
# Paper for language, time and keyboard
{ config, pkgs, ... }:
{
  # Time zone - from configuration.nix:42
  time.timeZone = "Europe/Berlin";

  # Language - from configuration.nix:46
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  # Keyboard in graphical environment - from configuration.nix:61
  services.xserver.xkb = {
    layout = "de";
    variant = "deadacute";
  };

  # Keyboard in text console - from configuration.nix:67
  console.keyMap = "de";
}
