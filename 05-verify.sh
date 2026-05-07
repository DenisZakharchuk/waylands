#!/usr/bin/env bash
# 05-verify.sh — Verify installation and session detection
# Run: bash 05-verify.sh   (no sudo needed)

set -uo pipefail

PASS=0
FAIL=0

check() {
  local label="$1"
  local result="$2"  # "ok" or "fail"
  local detail="${3:-}"
  if [[ "$result" == "ok" ]]; then
    echo "  [ok]   $label${detail:+  ($detail)}"
    ((PASS++)) || true
  else
    echo "  [FAIL] $label${detail:+  — $detail}"
    ((FAIL++)) || true
  fi
}

check_cmd() {
  local label="$1"
  local cmd="$2"
  if command -v "$cmd" &>/dev/null; then
    check "$label" ok "$(command -v "$cmd")"
  else
    check "$label" fail "command not found: $cmd"
  fi
}

check_file() {
  local label="$1"
  local path="$2"
  if [[ -f "$path" ]]; then
    check "$label" ok "$path"
  else
    check "$label" fail "missing: $path"
  fi
}

check_pkg() {
  local pkg="$1"
  if dpkg -l "$pkg" 2>/dev/null | grep -q '^ii'; then
    check "$pkg" ok
  else
    check "$pkg" fail "not installed"
  fi
}

echo ""
echo "══════════════════════════════════════════════════════"
echo "  Session desktop files (LightDM auto-detects these)"
echo "══════════════════════════════════════════════════════"
check_file "Cinnamon session" /usr/share/xsessions/cinnamon.desktop
check_file "Sway session    " /usr/share/wayland-sessions/sway.desktop
check_file "Hyprland session" /usr/share/wayland-sessions/hyprland.desktop

echo ""
echo "══════════════════════════════════════════════════════"
echo "  Sway stack"
echo "══════════════════════════════════════════════════════"
check_cmd "sway        " sway
check_cmd "swaylock    " swaylock
check_cmd "swayidle    " swayidle
check_cmd "waybar      " waybar
check_cmd "fuzzel      " fuzzel
check_cmd "foot        " foot
check_cmd "mako        " mako
check_cmd "grim        " grim
check_cmd "slurp       " slurp
check_cmd "swappy      " swappy
check_cmd "wlsunset    " wlsunset
check_cmd "kanshi      " kanshi
check_cmd "brightnessctl" brightnessctl
check_cmd "playerctl   " playerctl

echo ""
echo "══════════════════════════════════════════════════════"
echo "  Hyprland stack"
echo "══════════════════════════════════════════════════════"
check_cmd "hyprland    " hyprland
check_cmd "hyprlock    " hyprlock
check_cmd "hypridle    " hypridle
check_cmd "hyprpaper   " hyprpaper
check_cmd "hyprsunset  " hyprsunset
check_cmd "kitty       " kitty

echo ""
echo "══════════════════════════════════════════════════════"
echo "  Shared tools"
echo "══════════════════════════════════════════════════════"
check_cmd "yazi        " yazi
check_cmd "wl-copy     " wl-copy
check_cmd "cliphist    " cliphist
check_cmd "xwayland    " Xwayland

echo ""
echo "══════════════════════════════════════════════════════"
echo "  Wayland flags (VS Code, Chromium)"
echo "══════════════════════════════════════════════════════"
check_file "VS Code flags      " "$HOME/.config/code-flags.conf"
check_file "VS Code OSS flags  " "$HOME/.config/code-oss-flags.conf"
check_file "Chromium flags     " "$HOME/.config/chromium-flags.conf"

echo ""
echo "══════════════════════════════════════════════════════"
echo "  Starter configs"
echo "══════════════════════════════════════════════════════"
check_file "Sway config        " "$HOME/.config/sway/config"
check_file "Hyprland config    " "$HOME/.config/hypr/hyprland.conf"
check_file "Mako config        " "$HOME/.config/mako/config"

echo ""
echo "══════════════════════════════════════════════════════"
echo "  Portals (screen sharing)"
echo "══════════════════════════════════════════════════════"
check_pkg xdg-desktop-portal-wlr
check_pkg xdg-desktop-portal-gtk
check_pkg xdg-desktop-portal-hyprland

echo ""
echo "══════════════════════════════════════════════════════"
echo "  Summary: $PASS passed, $FAIL failed"
echo "══════════════════════════════════════════════════════"
if [[ $FAIL -eq 0 ]]; then
  echo ""
  echo "  All checks passed. Reboot and select your session"
  echo "  at the LightDM login screen (gear icon)."
else
  echo ""
  echo "  Fix the items above, then re-run this script."
fi
echo ""
