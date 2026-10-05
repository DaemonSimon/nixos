{
  description = "simon@nixos - modular flake with home-manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # quickshell - your desktop shell
    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # home-manager - manages your personal files in /home/simon
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # lazyvim-nix - declarative LazyVim for neovim via home-manager
    lazyvim-nix = {
      url = "github:pfassina/lazyvim-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-citizen - Star Citizen helper (RSI Launcher + kernel/udev tuning)
    nix-citizen = {
      url = "github:LovingMelody/nix-citizen";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # xremap-flake - evdev-level key remapper
    xremap-flake.url = "github:xremap/nix-flake";

    # nix-flatpak - declarative Flatpak app management (Modrinth App)
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = { self, nixpkgs, quickshell, home-manager, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        # Your main house config
        ./hosts/nixos

        # evdev-level key remapper
        inputs.xremap-flake.nixosModules.default

        # declarative Flatpak apps (Modrinth App) - system-wide
        inputs.nix-flatpak.nixosModules.nix-flatpak

        # Your room helper - home-manager as a NixOS module
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "bak"; # move stale pre-existing files aside on switch instead of aborting
          home-manager.extraSpecialArgs = { inherit inputs; };
          # Load your room papers for user simon
          home-manager.users.simon = import ./modules/home;
        }
      ];
    };
  };
}
