{
  description = "@dbkegley Arch + Nix home-manager configuration";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Dank Material Shell CLI
    dms-cli = {
      url = "github:AvengeMedia/danklinux";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Dank Material Shell process monitor CLI
    dgop = {
      url = "github:AvengeMedia/dgop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }@inputs:
    let
      inherit (self) outputs;
      system = "x86_64-linux";
    in {
      formatter = nixpkgs.legacyPackages.${system}.alejandra;
      overlays = import ./overlays { inherit inputs; };
      homeConfigurations = {
        minimal = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs outputs; };
          modules =
            [ { kegs = { isDesktop = false; }; } ./home-manager/home.nix ];
        };
        work = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs outputs; };
          modules = [
            {
              kegs = {
                isDesktop = false;
                isWork = true;
              };
            }
            ./home-manager/home.nix
          ];
        };
        desktop = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs outputs; };
          modules =
            [ { kegs = { isDesktop = true; }; } ./home-manager/home.nix ];
        };
      };
    };
}
