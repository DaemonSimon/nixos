# modules/home/vesktop.nix
#
# Keeps the mute/deafen bridge alive inside Vesktop's Vencord install.
#
# Vencord's own updater rewrites vencord-custom/vencordDesktopMain.js every time
# it updates, which throws away the bridge we append to it. So we (1) re-append
# the bridge before every launch through a `vesktop` wrapper, and (2) watch the
# file so the systemd user path unit re-appends it the moment the updater touches
# it - that second bit also covers Vesktop's in-app relaunch, which skips the
# wrapper.
{ config, pkgs, lib, ... }:

let
  vesktopCfg = "${config.home.homeDirectory}/.config/vesktop";
  customDir = "${vesktopCfg}/vencord-custom";
  mainFile = "${customDir}/vencordDesktopMain.js";
  sessionFiles = "${vesktopCfg}/sessionData/vencordFiles";

  bridge = ./dotfiles/streamcontroller/discord-deafen/vesktop/vencord-bridge.js;
  jq = "${pkgs.jq}/bin/jq";
  flock = "${pkgs.util-linux}/bin/flock";

  # Idempotent: only ever appends the bridge, never overwrites Vencord itself.
  ensureBridge = pkgs.writeShellScript "vesktop-bridge-guard" ''
    set -eu
    cfg=${lib.escapeShellArg vesktopCfg}
    custom=${lib.escapeShellArg customDir}
    main=${lib.escapeShellArg mainFile}
    session=${lib.escapeShellArg sessionFiles}

    # Keep Vesktop pointed at our custom Vencord directory.
    if [ -f "$cfg/state.json" ]; then
      if [ "$(${jq} -r '.vencordDir // ""' "$cfg/state.json")" != "$custom" ]; then
        ${jq} --arg d "$custom" '.vencordDir = $d' "$cfg/state.json" > "$cfg/state.json.tmp"
        mv "$cfg/state.json.tmp" "$cfg/state.json"
      fi
    fi

    # Serialise the wrapper and the watch service so the bridge is appended once.
    mkdir -p "$custom"
    exec 9>"$custom/.bridge.lock"
    ${flock} 9

    # Nothing to do if the bridge is already there.
    if ! grep -qF '[vc-bridge]' "$main" 2>/dev/null; then
      # First run ever: assemble a Vencord directory from Vesktop's own files.
      if [ ! -f "$main" ] && [ -f "$session/vencordDesktopMain.js" ]; then
        cp "$session/vencordDesktopMain.js" \
           "$session/vencordDesktopPreload.js" \
           "$session/vencordDesktopRenderer.js" \
           "$session/vencordDesktopRenderer.css" \
           "$session/package.json" \
           "$custom/"
      fi
      if [ -f "$main" ]; then
        chmod u+w "$main"
        printf '\n' >> "$main"
        cat ${bridge} >> "$main"
        echo "vesktop-bridge: bridge (re)applied to $main"
      fi
    fi
  '';

  # Same launcher name, but the guard runs first.
  vesktopLauncher = pkgs.writeShellScriptBin "vesktop" ''
    ${ensureBridge}
    exec ${pkgs.vesktop}/bin/vesktop "$@"
  '';

  # Join the launcher with the real package so that share/applications/vesktop.desktop
  # and share/icons survive - writeShellScriptBin alone would drop them.
  vesktopWrapped = pkgs.symlinkJoin {
    name = "vesktop-wrapped-${pkgs.vesktop.version}";
    paths = [
      vesktopLauncher
      pkgs.vesktop
    ];
  };
in
{
  home.packages = [ vesktopWrapped ];

  # Re-append the bridge as soon as Vencord's updater rewrites the file.
  systemd.user.services.vesktop-bridge-fix = {
    Unit = {
      Description = "Re-apply the Vesktop mute/deafen bridge";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${ensureBridge}";
    };
  };

  systemd.user.paths.vesktop-bridge-watch = {
    Unit = {
      Description = "Watch Vesktop's Vencord main file for updates";
    };
    Path = {
      PathModified = mainFile;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
