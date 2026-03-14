{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
    catppuccin.url = "github:catppuccin/nix";
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    musnix  = { url = "github:musnix/musnix"; };

    # end-4/dots-hyprland (illogical-impulse Quickshell desktop)
    # flake = false because dots-hyprland is not a flake; nix treats it as a
    # plain source tree pinned in flake.lock.  Run `nix flake update
    # dots-hyprland` to pull the latest upstream commit.
    dots-hyprland = {
      url   = "github:end-4/dots-hyprland";
      flake = false;
    };

    # Quickshell – the QtQuick-based widget system used by dots-hyprland.
    # Using the upstream flake so we always get the version that matches the
    # dots config rather than whatever is in nixpkgs at a given time.
    quickshell.url = "github:quickshell-mirror/quickshell";
    
    hyprquickshot = {
      url = "github:jamdon2/hyprquickshot";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, catppuccin, zen-browser, ... }@inputs: {
    nixosConfigurations.ourokronii = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        inputs.musnix.nixosModules.musnix
        catppuccin.nixosModules.catppuccin
        inputs.home-manager.nixosModules.default
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = { inherit inputs; };
            users = {
              "kronii" = import ./home.nix;
            };
          };
        }
      ];
    };
  };
}
