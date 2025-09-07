{ config, pkgs, ... }: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    sessionVariables = { EDITOR = "hx"; };
    shellAliases = {
      hm-update = "home-manager switch --flake $HOME/nix/#desktop";
      k = "kubectl";
      ll = "ls -al --color=auto";
    };
  };
}
