#!/usr/bin/env bash
workspace=$(hyprctl -j activewindow | jq -r ".workspace.name")

if [[ "$workspace" =~ ^special:.* ]]; then
	echo "hiding special workspace" >> ~/out.json
	# TODO: This appears to be a bug? You have to togglespecial twice
	# in order to fully hide the special window
	hyprctl dispatch togglespecialworkspace $workspace
	hyprctl dispatch togglespecialworkspace $workspace
else 
	echo "killing active window" >> ~/out.json
	hyprctl dispatch killactive
fi
