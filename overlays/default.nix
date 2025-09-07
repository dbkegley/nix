{ inputs, ... }: {
  # https://nixos.wiki/wiki/Overlays
  unstable-packages = final: prev: {
    # expose nixpkgs-unstable under 'pkgs.unstable'
    unstable = import inputs.nixpkgs-unstable {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  # add custom packages from the 'pkgs' directory
  additions = final: prev: import ../pkgs inputs final.pkgs;

  modifications = final: prev:
    {
      # example = prev.example.overrideAttrs (oldAttrs: rec {
      # ...
      # });
    };
}
