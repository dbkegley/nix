# nix/home-manager/home.nix

{ config, pkgs, ... }:

let
  me = "david";
  email = "david@kegley.me";
  github = "dbkegley";
in {
  nix = {
    package = pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };
  home.username = "${me}";
  home.homeDirectory = "/home/${me}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    git
    curl
    font-awesome_5
    nerdfonts
    helix
  ];
  programs = {
    home-manager.enable = true;
    fzf.enable = true;
    jq.enable = true;
    direnv = {
      enable = true;
      nix-direnv = {
        enable = true;
      };
    };
    git = {
      enable = true;
      userName = "${github}";
      userEmail = "${email}";
    };
    ssh = {
      enable = true;
      addKeysToAgent = "yes";
    };
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      # completions.enable = true;
      syntaxHighlighting.enable = true;
      shellAliases = {
        ll = "ls -l";
        hm-update = "home-manager switch --flake $HOME/nix/#${me}";
      };
      history = {
        extended = true;
        ignoreSpace = true;
        share = false;
        size = 10000;
      };
      # profileExtra = "if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi";
    };
  };

  services = {
    ssh-agent.enable = true;
  };
}
