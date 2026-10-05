# modules/home/fish.nix
# Paper for your fish shell and shortcuts
{ config, pkgs, ... }:
{
  programs.fish = {
    enable = true;
    shellAbbrs = {
      rebuild = "sudo nixos-rebuild switch --flake .#nixos";
      update = "nix flake update";
      rebuild-test = "sudo nixos-rebuild dry-build --flake .#nixos";
      gs = "git status";
      gp = "git push";
    };
    shellAliases = {
      ll = "ls -la";
    };
    interactiveShellInit = ''
      echo "Welcome back Simon!"
    '';
    functions = {
      gac = {
        description = "git add all and commit with message";
        body = "git add . && git commit -m \"$argv\"";
      };
      fullpush = {
        description = "rebuild, git add, commit, push";
        body = "git add . && git commit -m \"$argv\" && git push";
      };
    };
  };
}
