{ config, pkgs, ... }:
{
  imports = [
    ../modules/system/users.nix
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

    environment.systemPackages = with pkgs; [
      vim
      curl
      wget
      system-manager
    ];
  };
}
