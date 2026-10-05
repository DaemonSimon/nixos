# modules/home/packages.nix
# YOUR shopping list - all programs that are only for YOU (no boss key needed)
# This is the same list that was in configuration.nix:89, now moved to your room
{ config, pkgs, inputs, ... }:

{
  home.packages = with pkgs; [	
  prismlauncher
  spotify
	localsend
	pkgs.onlyoffice-desktopeditors
	code
	vim
	grim
	slurp
	wl-clipboard
	jq
	playerctl
	steam
	libnotify
	vesktop
	localsend
	kitty
	vscode
	inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
	nerd-fonts.hack
	nerd-fonts.symbols-only
	brightnessctl
	hyprpaper
	gnome-themes-extra
	# neovim is provided by programs.lazyvim (see ./lazyvim.nix) - not here
	# yazi is provided by programs.yazi (see ./yazi.nix) - not here
	ripgrep
	fd
	gcc
	gnumake
	unzip
	lazygit
	fzf
	git
	# rdtk (~/test) - local reddit tiktok feed: node runs it, chromium holds the login
	nodejs
	chromium
	moonlight-qt
	];
}
