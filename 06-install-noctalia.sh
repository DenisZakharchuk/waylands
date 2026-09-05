#!/usr/bin/env bash
# 06-install-noctalia.sh — Build & install Noctalia (native Wayland desktop shell) from source
# Run: bash 06-install-noctalia.sh   (script calls sudo internally where needed)
#
# Noctalia v5 is a native C++23 / OpenGL ES Wayland *desktop shell* — bars, dock,
# launcher, notifications, lock screen, wallpaper, control center. It has NO Qt/GTK
# and NO Quickshell dependency, and it runs ON TOP of a Wayland compositor. Your
# existing Sway (01) and Hyprland (02) installs are exactly the supported
# compositors, so run this after at least one of them is installed.
#
# There is no prebuilt Noctalia package for Ubuntu 24.04 Noble (their APT repo only
# targets Debian Trixie/Sid and Ubuntu 26.04), so it is built from source here.
#
# Two dependencies are newer than Ubuntu 24.04 ships and are handled automatically:
#   • WirePlumber 0.5 — built from source into /usr/local. The system WirePlumber
#                       0.4 stays the audio session manager; Noctalia only links the
#                       0.5 client library, so audio is not disrupted.
#   • stb headers     — stb_image_resize2.h / stb_image_write.h are vendored into
#                       /usr/local/include/stb (Ubuntu's libstb-dev predates them).
#
# The modern PipeWire 1.2, sdbus-c++ 2.x and wayland-protocols 1.49 required by
# Noctalia v5 come from the cppiber PPA (the same PPA 02-install-hyprland.sh uses);
# this script makes sure that PPA is present.

set -euo pipefail

NOCTALIA_REPO="https://github.com/noctalia-dev/noctalia"
NOCTALIA_BRANCH="${NOCTALIA_BRANCH:-main}"
WIREPLUMBER_VERSION="${NOCTALIA_WIREPLUMBER_VERSION:-0.5.10}"
WAYLAND_VERSION="${NOCTALIA_WAYLAND_VERSION:-1.24.0}"
PREFIX="/usr/local"
MULTIARCH="$(gcc -dumpmachine)"

BUILD_ROOT="$(mktemp -d)"
trap 'rm -rf "$BUILD_ROOT"' EXIT

# Noctalia needs GCC 14's libstdc++ for the C++23 <print> header.
export CC="${CC:-gcc-14}"
export CXX="${CXX:-g++-14}"

# Tolerant installer for optional runtime packages — a missing optional package
# produces a clear warning instead of aborting the whole script.
install_optional() {
  local pkg="$1"
  if sudo apt install -y "$pkg" 2>/dev/null; then
    echo "  [ok] $pkg"
  else
    echo "  [skip] $pkg — not available, skipping (optional)"
  fi
}

# ── cppiber PPA (modern pipewire / sdbus-c++ / wayland-protocols) ─────────────
echo "==> Ensuring cppiber PPA is present..."
if grep -rq "cppiber/hyprland" /etc/apt/sources.list.d/ 2>/dev/null; then
  echo "  [ok] cppiber/hyprland PPA already configured"
else
  sudo add-apt-repository -y ppa:cppiber/hyprland
fi
sudo apt update

# ── Build-time dependencies (Debian/Ubuntu list from Noctalia BUILDING.md) ────
echo "==> Installing Noctalia build dependencies..."
# g++-14 / gcc-14: Ubuntu 24.04 defaults to GCC 13, whose libstdc++ lacks the
# C++23 <print> header that Noctalia's sources require. GCC 14 provides it.
sudo apt install -y \
  build-essential gcc-14 g++-14 meson ninja-build pkg-config git curl ca-certificates \
  libwayland-dev libwayland-bin wayland-protocols \
  libegl-dev libgles-dev \
  libfreetype-dev libfontconfig-dev \
  libcairo2-dev libpango1.0-dev libharfbuzz-dev \
  libxkbcommon-dev libglib2.0-dev \
  libsecret-1-dev libsodium-dev \
  libsdbus-c++-dev \
  libpipewire-0.3-dev libspa-0.2-dev \
  libpam0g-dev libpolkit-agent-1-dev libpolkit-gobject-1-dev \
  libcurl4-openssl-dev libwebp-dev libjxl-dev libsndfile1-dev librsvg2-dev \
  libqalculate-dev libxml2-dev \
  libmd4c-dev libtomlplusplus-dev libical-dev \
  nlohmann-json3-dev libstb-dev \
  libjemalloc-dev \
  liblua5.4-dev \
  libffi-dev libexpat1-dev

# ── Runtime dependencies ──────────────────────────────────────────────────────
echo "==> Installing Noctalia runtime dependencies..."
# pipewire + wireplumber (0.4) = audio; polkitd = privilege prompts; git already
# installed above (needed on PATH for the plugin system / auto-update).
sudo apt install -y \
  pipewire pipewire-pulse wireplumber \
  polkitd

echo "==> Installing optional runtime dependencies..."
install_optional gnome-keyring                 # Secret Service (credential persistence)
install_optional upower                        # battery / power devices
install_optional ddcutil                       # external monitor brightness
install_optional fonts-noto                    # broad glyph coverage
install_optional fonts-noto-color-emoji        # colour emoji rendering

# ── Vendored stb headers (Ubuntu's libstb-dev predates stb_image_resize2.h) ───
echo "==> Vendoring updated stb headers into $PREFIX/include/stb ..."
sudo mkdir -p "$PREFIX/include/stb"
for header in stb_image_resize2.h stb_image_write.h; do
  if [[ -f "$PREFIX/include/stb/$header" ]]; then
    echo "  [skip] $header already vendored"
  else
    sudo curl -fsSL "https://raw.githubusercontent.com/nothings/stb/master/$header" \
      -o "$PREFIX/include/stb/$header"
    echo "  [ok] $header"
  fi
done

# ── Runtime linker path for the /usr/local libraries we build below ───────────
printf '%s\n%s\n' "$PREFIX/lib/$MULTIARCH" "$PREFIX/lib" \
  | sudo tee /etc/ld.so.conf.d/noctalia-local.conf >/dev/null
sudo ldconfig

# ── libwayland 1.23+ (Ubuntu 24.04 ships 1.22; Noctalia uses wl_proxy_get_display) ─
if pkg-config --atleast-version=1.23 wayland-client 2>/dev/null; then
  echo "==> libwayland $(pkg-config --modversion wayland-client) already ≥ 1.23 — skipping build"
else
  echo "==> Building libwayland $WAYLAND_VERSION from source (1.22 lacks wl_proxy_get_display)..."
  WL_SRC="$BUILD_ROOT/wayland"
  git clone --depth 1 --branch "$WAYLAND_VERSION" \
    https://gitlab.freedesktop.org/wayland/wayland.git "$WL_SRC"
  # Installed to /usr/local; 1.24 is a backward-compatible superset of the
  # system 1.22, so other apps keep working while Noctalia gets the new symbol.
  meson setup "$WL_SRC/build" "$WL_SRC" \
    --prefix="$PREFIX" --buildtype=release \
    -Ddocumentation=false -Dtests=false -Ddtd_validation=false
  meson compile -C "$WL_SRC/build"
  sudo meson install -C "$WL_SRC/build"
  sudo ldconfig
fi

# ── WirePlumber 0.5 (Ubuntu 24.04 only ships 0.4) ─────────────────────────────
if pkg-config --exists wireplumber-0.5; then
  echo "==> WirePlumber 0.5 already present ($(pkg-config --modversion wireplumber-0.5)) — skipping build"
else
  echo "==> Building WirePlumber $WIREPLUMBER_VERSION from source (0.5 not packaged for Ubuntu 24.04)..."
  WP_SRC="$BUILD_ROOT/wireplumber"
  git clone --depth 1 --branch "$WIREPLUMBER_VERSION" \
    https://gitlab.freedesktop.org/pipewire/wireplumber.git "$WP_SRC"
  # Build the library only-what-we-need: use system lua, skip GObject
  # introspection and docs. Installed to /usr/local so it never replaces the
  # apt-managed 0.4 session manager under /usr.
  meson setup "$WP_SRC/build" "$WP_SRC" \
    --prefix="$PREFIX" --buildtype=release \
    -Dsystem-lua=true -Dintrospection=disabled -Ddoc=disabled
  meson compile -C "$WP_SRC/build"
  sudo meson install -C "$WP_SRC/build"
  sudo ldconfig
fi

# ── Build & install Noctalia ──────────────────────────────────────────────────
echo "==> Cloning Noctalia ($NOCTALIA_BRANCH)..."
NOCTALIA_SRC="$BUILD_ROOT/noctalia"
git clone --depth 1 --branch "$NOCTALIA_BRANCH" "$NOCTALIA_REPO" "$NOCTALIA_SRC"

echo "==> Building Noctalia (release) — this compiles a large C++ project and takes a while..."
# Ensure the locally built WirePlumber 0.5 pkg-config file is discoverable.
export PKG_CONFIG_PATH="$PREFIX/lib/$MULTIARCH/pkgconfig:$PREFIX/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
meson setup "$NOCTALIA_SRC/build-release" "$NOCTALIA_SRC" \
  --prefix="$PREFIX" --buildtype=release -Dtests=disabled
meson compile -C "$NOCTALIA_SRC/build-release"
sudo meson install -C "$NOCTALIA_SRC/build-release"
sudo ldconfig

echo ""
echo "==> Noctalia $("$PREFIX/bin/noctalia" --version 2>/dev/null || echo installed) built successfully."
echo ""
echo "    Hyprland: the autostart from 04-configure.sh auto-detects Noctalia — it"
echo "    now starts Noctalia (bar + notifications) and skips waybar + mako. Nothing"
echo "    to edit. If your hyprland.lua predates this, re-run 04-configure.sh."
echo ""
echo "    Sway: add this line to ~/.config/sway/config (mako is not autostarted there):"
echo "      exec noctalia --daemon"
echo ""
echo "    Then log out and back into your Sway/Hyprland session."
echo "    Next: re-run 05-verify.sh to confirm the Noctalia stack."
