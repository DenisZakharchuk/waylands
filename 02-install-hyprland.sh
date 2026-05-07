#!/usr/bin/env bash
# 02-install-hyprland.sh — Add cppiber PPA and install Hyprland + ecosystem
# Run: bash 02-install-hyprland.sh
#
# NOTE: cppiber/hyprland is the only well-maintained PPA providing Hyprland
#       for Ubuntu 24.04 Noble (not in official repos until Ubuntu 25.04).

set -euo pipefail

echo "==> Adding cppiber/hyprland PPA..."
sudo add-apt-repository -y ppa:cppiber/hyprland
sudo apt update

echo "==> Installing Hyprland core..."
sudo apt install -y hyprland

echo "==> Installing Hyprland ecosystem tools..."
# These are all expected in the PPA; install individually so a missing
# package produces a clear warning rather than aborting everything.

install_pkg() {
  local pkg="$1"
  if sudo apt install -y "$pkg" 2>/dev/null; then
    echo "  [ok] $pkg"
  else
    echo "  [skip] $pkg — not available in PPA, skipping"
  fi
}

install_pkg hyprlock
install_pkg hypridle
install_pkg hyprpaper
install_pkg hyprsunset
install_pkg hyprpicker
install_pkg xdg-desktop-portal-hyprland

echo "==> Installing shared stack tools (waybar, fuzzel, kitty, mako, grim, etc.)..."
# These are all in official Ubuntu repos
sudo apt install -y \
  waybar \
  fuzzel \
  kitty \
  mako-notifier \
  grim \
  slurp \
  swappy \
  wl-clipboard \
  cliphist \
  policykit-1-gnome \
  xwayland

echo ""
echo "==> Hyprland stack installed successfully."
echo "    Next: run 03-install-yazi.sh"
