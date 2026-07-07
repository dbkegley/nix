{ inputs, ... }:
{
  # https://nixos.wiki/wiki/Overlays
  unstable-packages = final: prev: {
    # expose nixpkgs-unstable under 'pkgs.unstable'
    unstable = import inputs.nixpkgs-unstable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };

  # add custom packages from the 'pkgs' directory
  additions = final: prev: import ../pkgs inputs final;

  # Fix yay version reporting
  yay-fix = import ./yay.nix;

  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };
}
