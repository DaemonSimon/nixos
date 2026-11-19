{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.quickemu ];

  users.users."simon".extraGroups = [ "kvm" ];

  systemd.tmpfiles.rules = [
    "d /home/simon/VMs 0755 simon users -"
  ];
}
