{ config, ... }:
{
  imports = [
    # ./system/users.nix
    # ./system/niri.nix
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
