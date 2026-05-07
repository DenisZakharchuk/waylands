#!/usr/bin/env bash
# 01-install-sway.sh — Install Sway and companion stack from official Ubuntu 24.04 repos
# Run: bash 01-install-sway.sh

set -euo pipefail

echo "==> Updating package lists..."
sudo apt update

echo "==> Installing Sway stack..."
sudo apt install -y \
  sway \
  swaybg \
  sway-backgrounds \
  swaylock \
  swayidle \
  waybar \
  fuzzel \
  foot \
  mako-notifier \
  grim \
  slurp \
  wl-clipboard \
  cliphist \
  wlsunset \
  kanshi \
  xdg-desktop-portal-wlr \
  xdg-desktop-portal-gtk \
  policykit-1-gnome \
  xwayland \
  brightnessctl \
  playerctl

echo ""
echo "==> Sway stack installed successfully."
echo "    Next: run 02-install-hyprland.sh"
