# If the prompt gets slow, try setting the following to see what command is taking a while:
# set -o xtrace
# Revert with:
# set +o xtrace

# You may need to manually set your language environment
export LANG=en_US.UTF-8

export NVM_LAZY_LOAD=true

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git nvm)
source $ZSH/oh-my-zsh.sh

export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
HIST_STAMPS="yyyy-mm-dd"

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="true"

# No sharing history across sessions. Overrides defaults in $ZSH/lib/history.zsh
unsetopt share_history
# Do not append after command completes (with elapsed time)
unsetopt inc_append_history_time
# Append to history file incrementally rather than waiting for shell exit.
setopt inc_append_history

DISABLE_UNTRACKED_FILES_DIRTY="true"

ZSH_THEME_GIT_PROMPT_PREFIX="%{$reset_color%}%{$fg[white]%}["
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[red]%}●%{$fg[white]%}]%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_CLEAN="]%{$reset_color%} "

# probably want to use "names" when we aren't on xterm-256. eh.
# https://scriptingosx.com/2019/07/moving-to-zsh-06-customizing-the-zsh-prompt/
# configure iterm2 as xterm-256
# https://jonasjacek.github.io/colors/

# https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/kubectl
PROMPT='%F{76}%n%f@%F{69}%m%f:%1~ $(git_prompt_info)»%b '

# vim #
alias vi="nvim"
export EDITOR=vi
export VISUAL="$EDITOR"

# k8s #
# install krew plugins + autocomplete
# https://gist.github.com/dbkegley/42c1d4ac7ffd15dff644d514333956a0
PATH="$PATH:$HOME/.krew/bin"
alias k=kubectl
export KUBENS_IGNORE_FZF=1
export KUBECTX_IGNORE_FZF=1

# minikube #
# eval $(minikube docker-env)

git-branch-prune() {
  for b in $(git branch --format='%(refname:short)' | grep -v 'main\|master'); do git branch -d $b; done
}

# jwt decoder #
jwt() {
  echo "$1" | jq -R 'split(".") | .[0],.[1] | @base64d | fromjson'
}

# uv #
[ ! -f  "$HOME/.oh-my-zsh/completions/_uv" ] && \
  uv --generate-shell-completion zsh > "$HOME/.oh-my-zsh/completions/_uv"
[ ! -f  "$HOME/.oh-my-zsh/completions/_uvx" ] && \
  uvx --generate-shell-completion zsh > "$HOME/.oh-my-zsh/completions/_uvx"

# golang #
export PATH=$PATH:/usr/local/go/bin

# aws #
AWS_PROFILE="connect"
complete -C '/usr/local/bin/aws_completer' aws

# azure #
#source $(brew --prefix)/etc/bash_completion.d/az

# nodejs #
export PATH="$PATH:$HOME/.yarn/bin"
export NVM_LAZY=1
export NVM_DIR="$HOME/.nvm"
#[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# load ~/.env if it exists
if [ -f ~/.env ]; then
  set -o allexport; source ~/.env; set +o allexport
fi

# add Pulumi to the PATH
export PATH=$PATH:/home/david/.pulumi/bin
