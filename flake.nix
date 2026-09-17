{
  description = "@dbkegley Arch + Nix home-manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    arch-package-sync.url = "path:./arch-package-sync";

    system-manager = {
      url = "github:numtide/system-manager";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      system-manager,
      ...
    }@inputs:
    let
      inherit (self) outputs;
      system = "x86_64-linux";
      darwinSystem = "aarch64-darwin";
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;
      formatter.${darwinSystem} = nixpkgs.legacyPackages.${darwinSystem}.nixfmt;
      overlays = import ./overlays { inherit inputs; };

      systemConfigs.arch = system-manager.lib.makeSystemConfig {
        modules = [
          {
            nixpkgs.hostPlatform = system;
            system-manager.allowAnyDistro = true;
          }
          ./modules/kegs.nix
          ./modules/system.nix
        ];
      };

      homeConfigurations.arch = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = {
          inherit inputs outputs;
          isDarwin = false;
        };
        modules = [
          ./modules/kegs.nix
          ./modules/home.nix
          inputs.arch-package-sync.nixosModules.default
        ];
      };

      homeConfigurations.darwin = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${darwinSystem};
        extraSpecialArgs = {
          inherit inputs outputs;
          isDarwin = true;
        };
        modules = [
          ./modules/kegs.nix
          ./modules/home.nix
          (
            { config, ... }:
            {
              kegs.email = "david.kegley@posit.co";
              kegs.homeDir = "/Users/${config.kegs.username}";
            }
          )
        ];
      };
    };
}
