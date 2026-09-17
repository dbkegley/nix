{ lib, isDarwin, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    sessionVariables = {
      EDITOR = "hx";
    };
    shellAliases = {
      hm-update = "home-manager switch --flake $HOME/nix/#${if isDarwin then "darwin" else "arch"}";
      hm-rollback = "home-manager generations | head -2 | tail -1 | awk '{print $NF}' | xargs -I{} sh -c '{}/activate'";
      k = "kubectl";
      ll = "ls -al --color=auto";
    }

    # arch only aliases
    // lib.optionalAttrs (!isDarwin) {
      zed = "zeditor";
      sm-update = "system-manager switch --flake $HOME/nix#arch --sudo";
      aps = "arch-package-sync --remove-orphans";
    };

    history = {
      size = 100000;
      save = 100000;
      path = "$HOME/.zsh_history";
      extended = true;
      ignoreDups = true;
      share = true;
    };

    initContent = ''
      # Additional history options
      setopt APPEND_HISTORY
      setopt INC_APPEND_HISTORY
      setopt HIST_SAVE_NO_DUPS

      # zsh up/down arrow history prefix search
      autoload -Uz history-search-end
      zle -N history-beginning-search-backward-end history-search-end
      zle -N history-beginning-search-forward-end history-search-end

      # Bind arrow keys - using escape sequences directly as fallback
      bindkey "^[[A" history-beginning-search-backward-end  # Up arrow
      bindkey "^[[B" history-beginning-search-forward-end   # Down arrow

      # Also bind using terminfo if available
      [[ -n "$terminfo[kcuu1]" ]] && bindkey "$terminfo[kcuu1]" history-beginning-search-backward-end
      [[ -n "$terminfo[kcud1]" ]] && bindkey "$terminfo[kcud1]" history-beginning-search-forward-end

      # Completions for tools that generate them at runtime. Native nixpkgs
      # completions (git, gh, just, ...) are picked up automatically from
      # fpath via enableCompletion; only runtime-generated ones go here.
      # Each is guarded so a missing tool doesn't error on shell startup.

      # aws uses a bash-style completer, so enable bashcompinit for `complete -C`.
      autoload -Uz bashcompinit && bashcompinit

      command -v jj >/dev/null && source <(COMPLETE=zsh jj)
      command -v kubectl >/dev/null && source <(kubectl completion zsh)
      command -v aws_completer >/dev/null && complete -C aws_completer aws

      jj-bookmark-prune() {
        jj bookmark list -r 'stale_bookmarks()' -T 'name ++ "\n"' | xargs -r jj bookmark delete
      }
    '';
  };
}
