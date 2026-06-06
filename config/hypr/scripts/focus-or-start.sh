#!/usr/bin/env bash

cmd="$1"
class="$2"

# Debug logging
echo "[$(date +%H:%M:%S)] focus-or-start called with cmd='$cmd' class='$class'" >> /tmp/focus-or-start.log

# Get current workspace
current_workspace=$(hyprctl -j activeworkspace | jq -r '.id')

# Find windows matching the class (excluding special workspaces)
matching_window=$(hyprctl -j clients | \
	jq -r ".[] | select(.class == \"${class}\" and (.workspace.name | startswith(\"special\") | not)) | .workspace.id" | head -1)

if [[ "$matching_window" != "" ]]; then
	if [[ "$matching_window" == "$current_workspace" ]]; then
		echo "starting new instance of $class on current workspace"
		uwsm app -- ${cmd}
	else
		echo "focusing $class on workspace $matching_window"
		hyprctl dispatch "hl.dsp.focus({ workspace = \"${matching_window}\" })"
	fi
else
	echo "starting $class"
	uwsm app -- ${cmd}
fi
