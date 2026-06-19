#!/usr/bin/env bash
# source: https://github.com/niri-wm/niri/discussions/2602#discussioncomment-16258478
#
# Focus an already running app by shortname or reverse DNS identifier.
# If the app is not running then spawn a new instance.
#
# Examples:
#   focus-or-spawn ghostty [ARGS]
#   focus-or-spawn com.mitchellh.ghostty [ARGS]

set -o errexit
set -o pipefail
set -o nounset

APP="${1}"

APP_ID=$(
  niri msg --json windows |
    jq --arg app "${APP}" '
    [
      .[]
      | select(
          .app_id
          | ascii_downcase
          | endswith($app | ascii_downcase)
        )
    ]
    [-1]
    | .id
  '
)

if [ "${APP_ID}" == "null" ]; then
  # We shift here so that $@ has all of the arguments but not the app name.
  shift

  # APP supports the shortname (ghostty) and reverse DNS id (com.mitchellh.ghostty)
  # so let's extract the last segment using . to split on.
  #
  # When the binary name differs from the app-id (e.g. app-id dev.zed.Zed but
  # the binary is "zeditor"), set FOS_SPAWN to override the spawned command.
  SPAWN_APP="${FOS_SPAWN:-${APP##*.}}"

  niri msg action spawn -- "${SPAWN_APP}" "$@"
else
  niri msg action focus-window --id "${APP_ID}"
fi
