#!/usr/bin/env bash
#
# PostToolUse and PostToolUseFailure hook: when a command's output contains a
# known error message, add instructions for Claude next to the output.
# The command result does not change.
# The whole hook input JSON is searched, so the match does not depend on
# which field (stdout, stderr, error) holds the message.
input=$(cat)
event=$(jq -r '.hook_event_name // empty' <<< "$input" 2> /dev/null)
event=${event:-PostToolUse}

guidance=()

# Each rule: an extended regex for the error text, then the instructions.
rule() {
  if grep -qE -- "$1" <<< "$input"; then
    guidance+=("$2")
  fi
}

rule 'colima is not running' \
  'Colima is running. This error means that just ran inside the sandbox, because the command was not a plain just call. Run just as the whole command, with no cd, &&, ;, pipes, or redirects. For a worktree or jj workspace, put the path before the recipe name, for example: just .claude/worktrees/work1/test connect/store'

rule 'x509: OSStatus -26276|tls: failed to verify certificate' \
  'This error means that gh ran inside the sandbox, because the command was not a plain gh call. Run gh as the whole command, with no cd, &&, ;, pipes, or redirects. To filter the output, use --json with --jq. Do not use curl with the gh token.'

[ "${#guidance[@]}" -eq 0 ] && exit 0

context=$(printf '%s\n\n' "${guidance[@]}")
jq -n --arg event "$event" --arg context "$context" \
  '{hookSpecificOutput: {hookEventName: $event, additionalContext: $context}}'
