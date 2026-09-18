{
  description = "@dbkegley Arch + Nix home-manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    arch-package-sync.url = "path:./arch-package-sync";

    system-manager = {
      url = "github:numtide/system-manager";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Installs and manages Homebrew itself, so the nix-darwin homebrew module
    # has a brew to drive. nix-darwin does not install Homebrew on its own.
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # jj built from a pinned upstream commit, using jj's own flake and its
    # locked inputs. To move to a newer commit, change the rev and run
    # `nix flake lock`.
    jj.url = "github:jj-vcs/jj/f1b29bced933e289096a9c98276153e29dd95674";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      system-manager,
      nix-darwin,
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

      darwinConfigurations.darwin = nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs outputs; };
        modules = [
          # configuration
          ./modules/kegs.nix
          ./modules/kegs-darwin.nix
          ./modules/system/darwin.nix
          ./modules/system/aerospace.nix

          # homebrew
          inputs.nix-homebrew.darwinModules.nix-homebrew
          ./modules/system/homebrew.nix

          # home-manager
          home-manager.darwinModules.home-manager
          (
            { config, ... }:
            {
              home-manager.extraSpecialArgs = {
                inherit inputs outputs;
                isDarwin = true;
              };
              home-manager.users.${config.kegs.username}.imports = [
                ./modules/kegs.nix
                ./modules/kegs-darwin.nix
                ./modules/home.nix
              ];
            }
          )
        ];
      };
    };
}
