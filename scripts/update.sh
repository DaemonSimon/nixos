#!/usr/bin/env bash
#
# update - one command for the whole maintenance run.
#
#     sudo update
#
#  1. git backup of whatever you changed    (also stages new files, otherwise nix cannot see them)
#  2. nix flake update                      (bump flake.lock)
#  3. nixos-rebuild dry-build --flake .#nixos
#  4. nixos-rebuild switch   --flake .#nixos
#  5. flatpak update
#  6. nix-collect-garbage --delete-older-than 14d + nix-store --optimise
#  7. commit the lock bump, push
#
# Prints a summary at the end. Stops before step 4 if the build fails.

set -euo pipefail

PATH="/run/current-system/sw/bin:/run/wrappers/bin:/usr/bin:/bin"
export PATH
export LC_ALL=C
# a maintenance script must never block on a password prompt. If the credential
# helper fails, the push fails and the summary reports it instead of hanging.
export GIT_TERMINAL_PROMPT=0

REPO=/etc/nixos
FLAKE="$REPO#nixos"
# how far back old generations are kept. Rebuilds are frequent enough here
# that a week of history is plenty, but two weeks leaves a real rollback window.
GC_OLDER_THAN="14d"

# every summary field is declared before the trap exists, so a failure on the
# very first line can still print a complete summary under `set -u`
S_BACKUP="-"; S_INPUTS="-"; S_BUILD="-"
S_FATPAK="-"; S_GC="-"; S_OPT="-"
S_REMOTE="-"; S_REBOOT="-"; S_ERROR=""
KERNEL_BEFORE="unknown"; KERNEL_AFTER="unknown"

if [ "$(id -u)" -ne 0 ]; then
  printf 'update needs root, run:\n\n    sudo update\n\n' >&2
  exit 1
fi

OWNER="${SUDO_USER:-root}"
OWNER_HOME="$(getent passwd "$OWNER" | cut -d: -f6 || true)"
OWNER_HOME="${OWNER_HOME:-/root}"

# git and nix both have to write into $REPO as the repo's owner. Running them
# as root would leave root-owned files behind and git would start refusing the
# repo with "detected dubious ownership".
as_owner() {
  runuser -u "$OWNER" -- env HOME="$OWNER_HOME" PATH="$PATH" "$@"
}

if [ -t 1 ]; then
  B=$'\033[1m'; DIM=$'\033[2m'; OFF=$'\033[0m'
  RED=$'\033[31m'; GRN=$'\033[32m'; YLW=$'\033[33m'
else
  B=''; DIM=''; OFF=''; RED=''; GRN=''; YLW=''
fi

step() { printf '\n%s== %s%s\n' "$B" "$*" "$OFF"; }
ok()   { printf '   %s%s%s\n' "$GRN" "$*" "$OFF"; }
info() { printf '   %s%s\n' "$*" "$DIM"; }
bad()  { printf '   %s%s%s\n' "$RED" "$*" "$OFF"; }

human_kb() {
  awk -v k="${1:-0}" 'BEGIN {
    if (k < 0) k = -k
    split("KiB MiB GiB TiB PiB", u, " ")
    i = 1
    while (k >= 1024 && i < 5) { k /= 1024; i++ }
    printf "%.1f %s", k, u[i]
  }'
}

# join stdin lines with a separator. `paste -sd', '` cannot do this: paste
# cycles its delimiters one character at a time, so it yields "a,b c".
join_by() {
  awk -v s="$1" 'NR > 1 { printf "%s", s }
                 { printf "%s", $0 }
                 END { if (NR > 0) printf "\n" }'
}

current_gen() {
  local link
  link="$(readlink /nix/var/nix/profiles/system 2>/dev/null || true)"
  link="${link##*/}"
  link="${link#system-}"
  printf '%s' "${link%-link}"
}

print_summary() {
  step "Summary"
  printf '   %-9s %s\n' "backup"   "$S_BACKUP"
  printf '   %-9s %s\n' "inputs"   "$S_INPUTS"
  printf '   %-9s %s\n' "system"   "$S_BUILD"
  printf '   %-9s %s\n' "flatpak"  "$S_FATPAK"
  printf '   %-9s %s\n' "garbage"  "$S_GC"
  printf '   %-9s %s\n' "optimise" "$S_OPT"
  printf '   %-9s %s\n' "remote"   "$S_REMOTE"
  if [ -n "$S_ERROR" ]; then
    printf '   %-9s %s%s%s\n' "error" "$RED" "$S_ERROR" "$OFF"
  elif [ "$S_REBOOT" = "needed" ]; then
    printf '   %-9s %s%s%s\n' "reboot" "$YLW" \
      "$KERNEL_BEFORE -> $KERNEL_AFTER  (reboot required)" "$OFF"
  else
    printf '   %-9s %s\n' "reboot" "$KERNEL_AFTER (not required)"
  fi
}

on_error() {
  local line="${BASH_LINENO[0]:-?}"
  S_ERROR="failed near line $line - nothing after it ran"
  trap - ERR
  printf '\n'
  print_summary
  printf '\n%supdate stopped%s\n' "$RED" "$OFF"
  exit 1
}
trap on_error ERR

GEN_BEFORE="$(current_gen)"
AVAIL_BEFORE="$(df -Pk /nix | awk 'NR==2 {print $4}')"
KERNEL_BEFORE="$(uname -r)"

# ---- 1. backup ------------------------------------------------------------
step "1/7  Backup"
as_owner git -C "$REPO" add -A
if as_owner git -C "$REPO" diff --cached --quiet; then
  S_BACKUP="working tree already clean"
  ok "$S_BACKUP"
else
  N="$(as_owner git -C "$REPO" diff --cached --numstat | wc -l | tr -d ' ')"
  if [ "$N" = "1" ]; then
    MSG="update $(date '+%Y-%m-%d %H:%M') (1 file)"
  else
    MSG="update $(date '+%Y-%m-%d %H:%M') ($N files)"
  fi
  as_owner git -C "$REPO" commit -q -m "$MSG"
  SHORT="$(as_owner git -C "$REPO" rev-parse --short HEAD)"
  S_BACKUP="$N file(s) committed -> $SHORT"
  ok "$S_BACKUP"
fi

# ---- 2. flake inputs ------------------------------------------------------
step "2/7  Updating flake inputs"
if FLAKE_OUT="$(as_owner nix flake update --flake "$REPO" 2>&1)"; then
  if [ -n "$FLAKE_OUT" ]; then
    printf '%s\n' "$FLAKE_OUT"
  fi
  S_INPUTS="$(printf '%s\n' "$FLAKE_OUT" \
    | sed -n "s/.*Updated input '\([^']*\)'.*/\1/p" | sort -u | join_by ', ' || true)"
  if [ -z "$S_INPUTS" ]; then
    S_INPUTS="none - already current"
  fi
  ok "$S_INPUTS"
else
  printf '%s\n' "$FLAKE_OUT"
  S_INPUTS="nix flake update failed"
  false
fi

# ---- 3. build -------------------------------------------------------------
step "3/7  Building (dry-run first, changes nothing)"
nixos-rebuild dry-build --flake "$FLAKE"
ok "dry-build passed"

# ---- 4. activate ----------------------------------------------------------
step "4/7  Activating"
nixos-rebuild switch --flake "$FLAKE"
GEN_AFTER="$(current_gen)"
if [ -n "$GEN_AFTER" ]; then
  S_BUILD="generation $GEN_BEFORE -> $GEN_AFTER"
else
  S_BUILD="rebuilt"
fi
ok "$S_BUILD"

# ---- 5. flatpaks ----------------------------------------------------------
step "5/7  Flatpaks"
FLATPAK_PENDING="$(flatpak remote-ls --updates --columns=name 2>/dev/null | join_by ', ' || true)"
if [ -n "$FLATPAK_PENDING" ]; then
  info "pending: $FLATPAK_PENDING"
  flatpak update --noninteractive
  S_FATPAK="updated: $FLATPAK_PENDING"
else
  S_FATPAK="already current"
fi
ok "$S_FATPAK"

# ---- 6. garbage -----------------------------------------------------------
step "6/7  Garbage collection"
info "removing generations older than $GC_OLDER_THAN (keeps everything newer)"
nix-collect-garbage --delete-older-than "$GC_OLDER_THAN"
AVAIL_AFTER="$(df -Pk /nix | awk 'NR==2 {print $4}')"
FREED_KB=$(( AVAIL_AFTER - AVAIL_BEFORE ))
if [ "$FREED_KB" -gt 0 ]; then
  S_GC="$(human_kb "$FREED_KB") freed"
else
  S_GC="nothing to reclaim"
fi
ok "$S_GC"

info "hard-linking duplicate files (can take a few minutes on a cold store)"
OPT_OUT="$(nix-store --optimise 2>&1 || true)"
OPT_LINE="$(printf '%s\n' "$OPT_OUT" | grep -E 'bytes reclaimed' | tail -1 || true)"
if [ -n "$OPT_LINE" ]; then
  S_OPT="$OPT_LINE"
else
  S_OPT="done"
fi
ok "$S_OPT"

# ---- 7. record and push ---------------------------------------------------
step "7/7  Recording"
as_owner git -C "$REPO" add -A
if as_owner git -C "$REPO" diff --cached --quiet; then
  S_REMOTE="no further changes to record"
  info "$S_REMOTE"
else
  as_owner git -C "$REPO" commit -q -m "flake update $(date '+%Y-%m-%d %H:%M')"
  SHORT="$(as_owner git -C "$REPO" rev-parse --short HEAD)"
  S_REMOTE="committed $SHORT"
  if PUSH_OUT="$(as_owner git -C "$REPO" push 2>&1)"; then
    S_REMOTE="$S_REMOTE, pushed to origin/main"
    ok "$S_REMOTE"
  else
    printf '%s\n' "$PUSH_OUT"
    S_REMOTE="$S_REMOTE, push FAILED (run: git push)"
    bad "$S_REMOTE"
  fi
fi

# ---- reboot check ---------------------------------------------------------
KERNEL_AFTER="$(uname -r)"
KDIR="$(readlink -f /run/current-system/kernel 2>/dev/null || true)"
KDIR="$(basename "$(dirname "$KDIR")")"
KDIR="${KDIR#linux-}"
if [ -n "$KDIR" ]; then
  KERNEL_AFTER="$KDIR"
fi
if [ "$KERNEL_BEFORE" = "$KERNEL_AFTER" ]; then
  S_REBOOT="not required"
else
  S_REBOOT="needed"
fi

trap - ERR
print_summary
printf '\n'
exit 0
