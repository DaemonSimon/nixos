#!/bin/bash
hyprctl dispatch focusmonitor DP-2
hyprctl dispatch workspace "$1"
