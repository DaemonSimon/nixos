{ config, ... }:
{
  home.file."Pictures/Wallpapers" = {
    source = ./dotfiles/wallpapers;
    recursive = true;
  };
}
