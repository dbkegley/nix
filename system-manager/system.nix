{ pkgs, ... }:
{
  config = {

    nix.enable = true;
    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "david" ];
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
