{ config, ... }:
{
  imports = [
    ./system/greeter.nix
    ./system/keyring.nix
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
