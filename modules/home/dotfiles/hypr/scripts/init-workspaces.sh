#!/bin/bash
sleep 2
# Assign workspaces to monitors (prevents them from appearing on wrong monitor)
hyprctl keyword workspace "1, monitor:DP-2, persistent:true"
hyprctl keyword workspace "2, monitor:DP-2, persistent:true"
hyprctl keyword workspace "3, monitor:DP-2, persistent:true"
hyprctl keyword workspace "4, monitor:DP-2, persistent:true"
hyprctl keyword workspace "5, monitor:DP-1, persistent:true"
hyprctl keyword workspace "6, monitor:HDMI-A-1, persistent:true"
# Move any stray workspaces off DP-2 back to side monitors
hyprctl dispatch moveworkspacetomonitor 5 DP-1 2>/dev/null || true
hyprctl dispatch moveworkspacetomonitor 6 HDMI-A-1 2>/dev/null || true
hyprctl dispatch moveworkspacetomonitor 7 DP-1 2>/dev/null || true
hyprctl dispatch moveworkspacetomonitor 8 DP-1 2>/dev/null || true
hyprctl dispatch moveworkspacetomonitor 9 DP-1 2>/dev/null || true
hyprctl dispatch moveworkspacetomonitor 10 DP-1 2>/dev/null || true
# Create workspaces 1-4 on DP-2
hyprctl dispatch focusmonitor DP-2
hyprctl dispatch workspace 1
hyprctl dispatch workspace 2
hyprctl dispatch workspace 3
hyprctl dispatch workspace 4
hyprctl dispatch workspace 1
