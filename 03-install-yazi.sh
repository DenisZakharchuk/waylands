#!/usr/bin/env bash
# 03-install-yazi.sh — Install Yazi (Rust, Wayland-native terminal file manager)
# Yazi is not in Ubuntu 24.04 repos — installs pre-built binary from GitHub releases.
# Run: bash 03-install-yazi.sh

set -euo pipefail

INSTALL_DIR="/usr/local/bin"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Fetching latest Yazi release version..."
LATEST=$(curl -fsSL "https://api.github.com/repos/sxyazi/yazi/releases/latest" \
  | grep '"tag_name"' | cut -d'"' -f4)
echo "    Version: $LATEST"

ARCHIVE="yazi-x86_64-unknown-linux-musl.zip"
URL="https://github.com/sxyazi/yazi/releases/download/${LATEST}/${ARCHIVE}"

echo "==> Downloading $URL ..."
curl -fsSL "$URL" -o "$TMP_DIR/$ARCHIVE"

echo "==> Extracting..."
unzip -q "$TMP_DIR/$ARCHIVE" -d "$TMP_DIR"

# The zip extracts to a folder named yazi-x86_64-unknown-linux-musl/
EXTRACTED="$TMP_DIR/yazi-x86_64-unknown-linux-musl"

echo "==> Installing binaries to $INSTALL_DIR ..."
sudo install -m 755 "$EXTRACTED/yazi" "$INSTALL_DIR/yazi"
# ya is the Yazi package manager helper (optional but useful)
if [[ -f "$EXTRACTED/ya" ]]; then
  sudo install -m 755 "$EXTRACTED/ya" "$INSTALL_DIR/ya"
fi

echo "==> Installing preview dependency packages..."
# ffmpegthumbnailer — video thumbnails
# unar               — archive previews
# poppler-utils      — PDF previews
# imagemagick        — image conversion
# fd-find            — faster file search (used by yazi)
# ripgrep            — content search (used by yazi)
sudo apt install -y \
  ffmpegthumbnailer \
  unar \
  poppler-utils \
  imagemagick \
  fd-find \
  ripgrep

echo ""
echo "==> Yazi $(yazi --version 2>/dev/null || echo 'installed') — launch with: yazi"
echo "    To update later: re-run this script (it always pulls the latest release)."
echo "    Next: run 04-configure.sh"
