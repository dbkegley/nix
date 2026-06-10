{
  description = "@dbkegley Arch + Nix configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    system-manager = {
      url = "github:numtide/system-manager";
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
    in
    {
      formatter = nixpkgs.legacyPackages.${system}.nixfmt;
      overlays = import ./overlays { inherit inputs; };
      # homeConfigurations = {
      #   arch = home-manager.lib.homeManagerConfiguration {
      #     pkgs = nixpkgs.legacyPackages.${system};
      #     extraSpecialArgs = { inherit inputs outputs; };
      #     modules = [
      #       ./home-manager/home.nix
      #     ];
      #   };
      # };

      systemConfigs.arch = system-manager.lib.makeSystemConfig {
        modules = [
          home-manager.nixosModules.home-manager
          (
            { ... }:
            {
              nixpkgs.overlays = [
                outputs.overlays.unstable-packages
                outputs.overlays.additions
                outputs.overlays.modifications
              ];
            }
          )
          ./modules/options.nix
          ./modules/system.nix
          # todo:
          # - kde.nix
          # - niri.nix
          # - shell.nix (noctalia)
          # - zed.nix
          ./modules/ghostty.nix
          ./modules/dms.nix
        ];
      };
    };
}
