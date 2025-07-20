# nix/home-manager/home.nix

{ config, pkgs, pkgs-unstable, ... }:

let
  me = "david";
  email = "david@kegley.me";
  github = "dbkegley";
  packages = with pkgs; [
    git
    curl
    font-awesome_5
    nerdfonts
    uv
    go
    helix
    zellij
  ];
  # packages-unstable = with pkgs-unstable; [
  #   helix
  # ];
in {
  nix = {
    package = pkgs.nix;
    settings.experimental-features = [ "nix-command" "flakes" ];
  };
  home.username = "${me}";
  home.homeDirectory = "/home/${me}";
  home.stateVersion = "24.11";
  # home.packages = packages ++ packages-unstable;
  home.packages = packages;
  home.file = {
  #   ".zshrc".source = config.lib.file.mkOutOfStoreSymlink ./dotfiles/.zshrc;
    ".config/helix/config.toml".source = ../dotfiles/helix/config.toml;
    ".config/helix/languages.toml".source = ../dotfiles/helix/languages.toml;
  };
  programs = {
    home-manager.enable = true;
    fzf.enable = true;
    jq.enable = true;
    # direnv = {
    #   enable = true;
    #   nix-direnv = {
    #     enable = true;
    #   };
    # };
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
      oh-my-zsh = {
        enable = true;
        theme = "robbyrussell";
        plugins = ["git"];
      };
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
      profileExtra = "if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi";
    };
  };

  services = {
    ssh-agent.enable = true;
  };
}
