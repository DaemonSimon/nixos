# modules/home/kytyps5.nix
#
# KytyPS5 - experimental PlayStation 5 emulator (https://github.com/KytyPS5/KytyPS5).
#
# Upstream only ships a prebuilt Linux tarball that bundles its own Qt, so we
# unpack it into the Nix store and run it inside an FHS environment (it needs
# a normal /lib layout plus Vulkan/GL drivers). The tarball is pinned by hash;
# to update, change `version`/`rev` and the hash below.
#
# Start it with `kytyps5` (the launcher GUI) or from the app launcher.
{ pkgs, ... }:

let
  version = "2026-11-21-39936ff";

  kytyps5-unwrapped = pkgs.stdenvNoCC.mkDerivation {
    pname = "kytyps5-unwrapped";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/KytyPS5/KytyPS5/releases/download/KytyPS5-${version}/KytyPS5-${version}-Linux-x86_64.tar.gz";
      hash = "sha256-GAVGA9aggMsqYMwd/uXQUSxK68RvlH0fmiGF3uJHpsg=";
    };

    # The tarball has no top-level directory.
    sourceRoot = ".";

    installPhase = ''
      runHook preInstall
      mkdir -p $out/opt/kytyps5
      cp -r . $out/opt/kytyps5
      runHook postInstall
    '';
  };

  # The launcher wants to write next to itself (config, updates, shader cache),
  # which the read-only store forbids. So keep a writable copy in
  # ~/.local/share/kytyps5 and refresh it whenever the pinned version changes.
  kytyps5 = pkgs.buildFHSEnv {
    name = "kytyps5";
    targetPkgs = pkgs': with pkgs'; [
      stdenv.cc.cc.lib
      zlib
      libGL
      libglvnd
      vulkan-loader
      libxkbcommon
      fontconfig
      freetype
      dbus
      wayland
      alsa-lib
      libpulseaudio
      openssl
      libx11
      libxcb
      libxcb-cursor
      libxcb-image
      libxcb-keysyms
      libxcb-render-util
      libxcb-wm
    ];
    runScript = pkgs.writeShellScript "kytyps5-run" ''
      data="''${XDG_DATA_HOME:-$HOME/.local/share}/kytyps5"
      stamp="$data/.nix-version"
      if [ "$(cat "$stamp" 2>/dev/null)" != "${version}" ]; then
        mkdir -p "$data"
        cp -rf --no-preserve=mode,ownership ${kytyps5-unwrapped}/opt/kytyps5/. "$data/"
        chmod -R u+rwX "$data"
        echo "${version}" > "$stamp"
      fi
      cd "$data"
      exec ./kyty_launcher "$@"
    '';
  };
in
{
  home.packages = [ kytyps5 ];

  xdg.desktopEntries.kytyps5 = {
    name = "KytyPS5";
    genericName = "PlayStation 5 Emulator";
    exec = "kytyps5";
    terminal = false;
    categories = [ "Game" "Emulator" ];
  };
}
