# modules/home/yazi.nix
# Paper for yazi, the file manager
# yazi does NOT read $EDITOR - its built-in edit opener is hardcoded to "vi",
# so the opener has to be declared here. See `man 5 yazi-config`, [opener].
{ config, pkgs, ... }:
{
  programs.yazi = {
    enable = true;

    # Open files with nvim instead of vi, taking over the terminal while it runs.
    # %s is yazi's placeholder for the selected file(s) - it is NOT shell "$@",
    # which the shell would expand to nothing and leave nvim on an empty buffer.
    # See `man 5 yazi-config`, [opener].
    settings.opener.edit = [
      {
        run = "nvim %s";
        desc = "nvim";
        for = "unix";
        block = true;
      }
    ];
  };
}
