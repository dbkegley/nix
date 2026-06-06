{ config, pkgs, ... }: {
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    enableCompletion = true;
    sessionVariables = { EDITOR = "hx"; };
    shellAliases = {
      hm-update = "home-manager switch --flake $HOME/nix/#desktop";
      hm-rollback = "home-manager generations | head -2 | tail -1 | awk '{print $NF}' | xargs -I{} sh -c '{}/activate'";
      k = "kubectl";
      ll = "ls -al --color=auto";
    };
  };
}
