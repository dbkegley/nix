{
  description = "Ubuntu24 Nix";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "nixpkgs/nixpkgs-unstable";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";  # Follows stable nixpkgs by default
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, home-manager, ... }: let
    me = "david";
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
    pkgs-unstable = nixpkgs-unstable.legacyPackages.${system};
  in {
    homeConfigurations = {
      "${me}" = home-manager.lib.homeManagerConfiguration {

        # TODO: figure out how to pass pkgs-unstable into home.nix to install helix latest
        # or just use unstable as the default instead?

        # inherit pkgs pkgs-unstable;
        inherit pkgs;
        modules = [
          ./home-manager/home.nix
        ];
      };
    };
  };
}
