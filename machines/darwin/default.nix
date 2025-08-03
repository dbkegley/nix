{
  inputs,
  lib,
  ...
}: {
  imports = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-darwin";

  networking = {
    hostName = "david-mbp";
    computerName = "darwin";
  };

  kegs-dev = {
    stateVersion = "24.05";
    # gpg.enable = true;
    development-packages.enable = true;
    development-packages.tools.go = true;
    development-packages.tools.python = true;
    development-packages.tools.dev = true;
    # development-packages.tools.security = true;
    # development-packages.tools.networking = true;
    # development-packages.tools.database = true;
    # development-packages.tools.iac = true;
    # development-packages.tools.k8s = true;
    # development-packages.tools.cloud = true;
  };
}
