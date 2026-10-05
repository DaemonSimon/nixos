#!/usr/bin/env sh
# Apply a macOS XCursor theme at runtime and remember the choice.
#
# apple-cursor ships two right-handed themes: "macOS" (the classic
# black-outlined arrow, for light backgrounds) and "macOS-White" (for dark
# backgrounds). Because apple-cursor is in home.packages, both are reachable
# through XCURSOR_PATH, so switching between them needs no home-manager run.
#
# The theme switcher calls this for you; you normally don't need to run it:
#     cursor-theme.sh apply macOS-White 32
#     cursor-theme.sh restore
#
# `restore` is what runs at quickshell startup — it re-applies the persisted
# variant so that a home-manager switch (which resets dconf to the NixOS
# default) doesn't leave you on the wrong cursor.
set -eu

conf_dir=${XDG_CONFIG_HOME:-$HOME/.config}/quickshell
conf=$conf_dir/cursor.conf

default_name=macOS
default_size=32

# A theme name is only accepted if it matches the known apple-cursor layout AND
# a directory with real cursor files actually exists for it. Never interpolate
# caller input into a command string.
valid() {
  case $1 in
    # restrict to a safe charset before touching the filesystem
    *[!A-Za-z0-9_-]*) return 1 ;;
  esac
  case $1 in
    macOS | macOS-White) ;;
    *) return 1 ;;
  esac
  for dir in \
    "${XDG_DATA_HOME:-$HOME/.local/share}/icons" \
    "$HOME/.icons" \
    "/etc/profiles/per-user/$(id -un)/share/icons" \
    "$HOME/.local/state/nix/profiles/profile/share/icons"
  do
    [ -e "$dir/$1/cursors/left_ptr" ] && return 0
  done
  return 1
}

persist() {
  mkdir -p "$conf_dir"
  printf '%s %s\n' "$1" "$2" >"$conf"
}

# Apply everywhere we can reach. hyprctl covers the compositor (including
# XWayland and anything that lets the compositor draw its own cursor); dconf
# covers GTK, Electron and Qt using the gtk3 platform theme.
apply_theme() {
  _name=$1
  _size=$2

  # Non-fatal: if the compositor isn't up yet we still want the dconf write,
  # so new apps pick the theme up.
  hyprctl setcursor "$_name" "$_size" ||
    echo "cursor-theme.sh: hyprctl setcursor failed, continuing with dconf" >&2

  dconf write /org/gnome/desktop/interface/cursor-theme "'$_name'"
  dconf write /org/gnome/desktop/interface/cursor-size "$_size"
}

case ${1:-restore} in
  apply)
    name=${2:-}
    size=${3:-$default_size}
    [ -n "$name" ] || {
      echo "cursor-theme.sh: usage: $0 apply <theme> [size]" >&2
      exit 1
    }
    case $size in
      '' | *[!0-9]*) echo "cursor-theme.sh: bad size: $size" >&2; exit 1 ;;
    esac
    valid "$name" || {
      echo "cursor-theme.sh: not an installed macOS theme: $name" >&2
      exit 1
    }
    apply_theme "$name" "$size"
    persist "$name" "$size"
    ;;
  restore)
    name=$default_name
    size=$default_size
    if [ -f "$conf" ]; then
      # shellcheck disable=SC2162
      read -r name size <"$conf" || true
      valid "$name" || {
        name=$default_name
        size=$default_size
      }
      case ${size:-} in
        '' | *[!0-9]*) size=$default_size ;;
      esac
    fi
    apply_theme "$name" "$size"
    ;;
  *)
    echo "cursor-theme.sh: unknown command: $1" >&2
    echo "usage: $0 {apply <theme> [size]|restore}" >&2
    exit 1
    ;;
esac
