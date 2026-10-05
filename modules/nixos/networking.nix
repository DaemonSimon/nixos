# modules/nixos/networking.nix
# Paper for internet and network
{ config, pkgs, ... }:
{
  # Enable networking via NetworkManager - from configuration.nix:41
  networking.networkmanager.enable = true;

  # Tailscale - join your tailnet, MagicDNS for *.ts.net
  services.tailscale.enable = true;

  # Firewall - all closed by default, open only what you need
  # networking.firewall.allowedTCPPorts = [ ];
  # networking.firewall.allowedUDPPorts = [ ];
  # networking.firewall.enable = false;

  # Proxy if you need it
  # networking.proxy.default = "http://user:password@proxy:port/";
}
