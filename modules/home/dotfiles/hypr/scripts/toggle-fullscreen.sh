#!/bin/bash
# Toggle blocking of fullscreen requests from apps/games.
# Creates/removes a state file that settings/windowrules.lua reads on reload.
STATE="$HOME/.cache/hypr/fullscreen-suppress"
mkdir -p "$(dirname "$STATE")"

if [ -e "$STATE" ]; then
    rm -f "$STATE"
    notify-send -a "Hyprland" "Fullscreen suppression" "Disabled"
else
    : > "$STATE"
    notify-send -a "Hyprland" "Fullscreen suppression" "Enabled"
fi

hyprctl reload
