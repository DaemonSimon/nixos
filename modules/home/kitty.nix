# modules/home/kitty.nix
# Paper for your kitty terminal - starts fish automatically
{ config, pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    settings = {
      shell = "${pkgs.fish}/bin/fish";
      font_family = "JetBrains Mono";
      font_size = 12;
      background_opacity = "0.9";
      confirm_os_window_close = -1;
      enable_audio_bell = "no";
    };
    extraConfig = ''
      # Your personal kitty settings go here
    '';
  };
}
