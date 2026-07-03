{ config, ... }:
{
  imports = [
    ./system/secureboot.nix
    ./system/keyring.nix
    ./system/greeter.nix
    # ./system/shell.nix
  ];

  config = {

    nix.enable = true;
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ config.kegs.username ];
      build-users-group = "nixbld";
    };
  };
}
