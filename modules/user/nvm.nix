# nvm (Node Version Manager), from the `nvm` input pinned in flake.nix.
#
# nvm installs Node versions into $NVM_DIR, which must stay writable, so it is
# ~/.nvm. home-manager links nvm's scripts into it, giving the standard nvm
# layout: nvm-exec (used by `nvm exec`) sources nvm.sh from its own directory.
{ inputs, ... }:
{
  home.file = {
    ".nvm/nvm.sh".source = "${inputs.nvm}/nvm.sh";
    ".nvm/nvm-exec".source = "${inputs.nvm}/nvm-exec";
    ".nvm/bash_completion".source = "${inputs.nvm}/bash_completion";
  };

  # Lazy loading: sourcing nvm.sh slows every shell start, so it loads only on
  # the first `nvm` call. At startup, a Node version goes on PATH directly, so
  # node, npm, npx, and global npm tools work without nvm loaded: the version
  # named by nvm's `default` alias (e.g. "22" or "v20.11.0"), or the newest
  # installed one when the alias needs nvm to resolve (e.g. "lts/*").
  programs.zsh.initContent = ''
    export NVM_DIR="$HOME/.nvm"

    () {
      local want versions
      [[ -r $NVM_DIR/alias/default ]] && want=$(<"$NVM_DIR/alias/default")
      want=''${want#v}
      if [[ $want =~ '^[0-9]+(\.[0-9]+){0,2}$' ]]; then
        versions=( "$NVM_DIR"/versions/node/v$want(|.*)(N/nOn) )
      fi
      (( $#versions )) || versions=( "$NVM_DIR"/versions/node/v*(N/nOn) )
      (( $#versions )) && path=( "$versions[1]/bin" $path )
    }

    nvm() {
      unset -f nvm
      # --no-use: keep the Node already on PATH until `nvm use` is run.
      source "$NVM_DIR/nvm.sh" --no-use
      source "$NVM_DIR/bash_completion"
      nvm "$@"
    }
  '';
}
