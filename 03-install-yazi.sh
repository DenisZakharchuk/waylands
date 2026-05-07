#!/usr/bin/env bash
# 03-install-yazi.sh — Install Yazi (Rust, Wayland-native terminal file manager)
# Run: bash 03-install-yazi.sh

set -euo pipefail

echo "==> Installing Yazi and optional preview dependencies..."
sudo apt install -y yazi

# Optional: rich preview support inside foot/kitty
# ffmpegthumbnailer  — video thumbnails
# unar               — archive previews
# poppler-utils      — PDF previews
# imagemagick        — image conversion
echo "==> Installing Yazi preview dependency packages..."
sudo apt install -y \
  ffmpegthumbnailer \
  unar \
  poppler-utils \
  imagemagick \
  fd-find \
  ripgrep

echo ""
echo "==> Yazi installed. Launch with: yazi"
echo "    Next: run 04-configure.sh"
