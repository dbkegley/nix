#!/usr/bin/env bash
# PreToolUse hook: allow only read-only git and jj commands.
# Reads the tool input as JSON on stdin (Bash, Monitor, and run_in_terminal
# all pass the shell text in .tool_input.command). Exit 2 blocks the command.
cmd=$(jq -r '.tool_input.command // ""')

block() {
  echo "VCS write operations are blocked. The user manages version control with jj. Edit files in the current working copy and only use VCS read operations." >&2
  exit 2
}

# A word counts as a command only in command position: at the start of a line
# or after ; & | ( { ` or $(, optionally after wrapper commands (sudo, env,
# xargs, ...), shell keywords (then, do, ...), VAR=value assignments, or the
# start of a quoted script (sh -c '...', bash -lc "...", eval '...'). An
# optional leading backslash (\git) and path prefix (/usr/bin/git,
# ~/.nix-profile/bin/jj) are allowed. So `grep git README` is not treated as a
# git command.
start='(^|[;&|({`]|\$\()\s*'
quote="['\"]?"
shell_c="(ba|z|da)?sh(\\s+-\\S+)*\\s+-[A-Za-z]*c\\s+${quote}"
eval_="eval\\s+${quote}"
wrappers='((sudo|env|command|exec|time|nohup|nice|xargs|then|do|else|elif|if|while|until|!)(\s+-\S+)*\s+|[A-Za-z_][A-Za-z0-9_]*=\S*\s+|'"${shell_c}|${eval_}"')*'
cmdpos="${start}${wrappers}"'\\?(\S*/)?'
# One argument word: stops at whitespace and shell separators.
arg='[^[:space:];&|)`]+'

# For each invocation of tool $1 in $cmd, print its first two non-option words
# (the subcommand). $2 is a regex of global options that take a separate
# value word, which is skipped too.
subcommands() {
  local tool=$1 valued=$2
  echo "$cmd" | grep -oE "${cmdpos}${tool}(\s+${arg})*" | while IFS= read -r match; do
    local words args skip word
    read -ra words <<< "${match#*$tool}"
    args=()
    skip=0
    for word in "${words[@]}"; do
      # Drop quote characters, e.g. the closing quote in bash -c 'git status'.
      word=${word//[\"\']/}
      [ -n "$word" ] || continue
      if [ "$skip" = 1 ]; then
        skip=0
      elif [[ $word =~ ^($valued)$ ]]; then
        skip=1
      elif [[ $word != -* ]]; then
        args+=("$word")
        [ "${#args[@]}" -ge 2 ] && break
      fi
    done
    echo "${args[0]:-} ${args[1]:-}"
  done
}

# git: bare `git`, `git --version`, and read-only subcommands only.
while read -r first _; do
  case "$first" in
    "" | status | log | diff | show | blame | grep | shortlog | describe | \
      ls-files | ls-tree | cat-file | rev-parse | rev-list | merge-base | \
      name-rev | show-ref | for-each-ref | diff-tree | check-ignore | \
      check-attr | count-objects | help | version) ;;
    *) block ;;
  esac
done <<< "$(subcommands git '-C|-c|--git-dir|--work-tree|--namespace|--config-env|--super-prefix')"

# jj: read-only subcommands only. Bare `jj` runs `jj log`.
while read -r first second; do
  case "$first" in
    "" | log | show | diff | status | st | evolog | obslog | interdiff | help | version | root) ;;
    op) [[ $second =~ ^(log|show|diff)$ ]] || block ;;
    file) [[ $second =~ ^(show|list|annotate)$ ]] || block ;;
    bookmark | b) [[ $second =~ ^(list|l)$ ]] || block ;;
    tag) [[ $second == list ]] || block ;;
    config) [[ $second =~ ^(list|get|path)$ ]] || block ;;
    workspace) [[ $second =~ ^(list|root)$ ]] || block ;;
    *) block ;;
  esac
done <<< "$(subcommands jj '-R|--repository|--at-op|--at-operation|--color|--config|--config-file')"

exit 0
