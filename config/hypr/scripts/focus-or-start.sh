#!/usr/bin/env bash

cmd="$1"
class="$2"

workspace=$(hyprctl -j clients | \
	jq -r ".[] | select(.class == \"${class}\")")
wrk_id=$(echo $workspace | jq -r '.workspace.id')
wrk_name=$(echo $workspace | jq -r '.workspace.name')

if [[ "$wrk_name" =~ ^special:.*$ ]]; then
	echo "focusing special $class"
  # hyprctl dispatch togglespecialworkspace $wrk_name
	hyprctl dispatch workspace $wrk_name
elif [[ "$wrk_id" != "" ]]; then
	echo "focusing $class"
	hyprctl dispatch workspace $wrk_id
else
	echo "starting $class"
	uwsm app -- ${cmd}
fi
