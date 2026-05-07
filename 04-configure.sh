#!/usr/bin/env bash
# 04-configure.sh — Configure Wayland flags, copy starter configs
# Run: bash 04-configure.sh   (no sudo needed)

set -euo pipefail

# ── VS Code: force native Wayland via Ozone ──────────────────────────────────
# Applies to: code (Microsoft), code-oss (open source build)

configure_vscode() {
  local flags_file="$HOME/.config/code-flags.conf"
  if [[ -f "$flags_file" ]]; then
    echo "  [skip] $flags_file already exists — not overwriting"
    echo "         Ensure it contains: --ozone-platform=wayland"
  else
    cat > "$flags_file" <<'EOF'
--ozone-platform=wayland
--enable-features=WaylandWindowDecorations
EOF
    echo "  [ok] $flags_file"
  fi

  # code-oss uses a separate flags file
  local oss_flags="$HOME/.config/code-oss-flags.conf"
  if [[ -f "$oss_flags" ]]; then
    echo "  [skip] $oss_flags already exists"
  else
    cp "$HOME/.config/code-flags.conf" "$oss_flags"
    echo "  [ok] $oss_flags"
  fi
}

# ── Chromium: force native Wayland via Ozone ─────────────────────────────────

configure_chromium() {
  local flags_file="$HOME/.config/chromium-flags.conf"
  if [[ -f "$flags_file" ]]; then
    echo "  [skip] $flags_file already exists — not overwriting"
    echo "         Ensure it contains: --ozone-platform=wayland"
  else
    cat > "$flags_file" <<'EOF'
--ozone-platform=wayland
EOF
    echo "  [ok] $flags_file"
  fi
}

# ── Sway starter config ───────────────────────────────────────────────────────

configure_sway() {
  local sway_conf="$HOME/.config/sway/config"
  if [[ -f "$sway_conf" ]]; then
    echo "  [skip] $sway_conf already exists — not overwriting"
  else
    mkdir -p "$HOME/.config/sway"
    cp /etc/sway/config "$sway_conf"
    # Propagate Wayland environment to D-Bus and systemd so Electron apps
    # (VS Code, Chromium) can auto-detect Wayland without extra flags.
    cat >> "$sway_conf" <<'EOF'

# ── Wayland environment propagation ──────────────────────────────────────────
# Required for Electron apps, xdg-desktop-portal, and screen sharing to work.
exec dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY
EOF
    echo "  [ok] $sway_conf (copied from /etc/sway/config + env propagation added)"
  fi
}

# ── Hyprland starter config ───────────────────────────────────────────────────

configure_hyprland() {
  local hypr_conf="$HOME/.config/hypr/hyprland.conf"
  if [[ -f "$hypr_conf" ]]; then
    echo "  [skip] $hypr_conf already exists — not overwriting"
  else
    local source_conf=""
    # Hyprland ships an example config — find it
    for candidate in \
      /usr/share/hyprland/hyprland.conf \
      /etc/hypr/hyprland.conf; do
      if [[ -f "$candidate" ]]; then
        source_conf="$candidate"
        break
      fi
    done

    mkdir -p "$HOME/.config/hypr"

    if [[ -n "$source_conf" ]]; then
      cp "$source_conf" "$hypr_conf"
      echo "  [ok] $hypr_conf (copied from $source_conf)"
    else
      # Hyprland not installed yet, or no example config found — create minimal placeholder
      cat > "$hypr_conf" <<'EOF'
# Minimal Hyprland config — replace with a full config or run hyprland --config to generate one.
# See: https://wiki.hyprland.org/Configuring/Configuring-Hyprland/

monitor=,preferred,auto,1

input {
    kb_layout = us
    follow_mouse = 1
    touchpad {
        natural_scroll = true
    }
}

general {
    gaps_in = 5
    gaps_out = 10
    border_size = 2
}

decoration {
    rounding = 8
    blur {
        enabled = true
        size = 3
        passes = 1
    }
}

animations {
    enabled = true
}

# Default terminal (change to your preference)
bind = SUPER, Return, exec, kitty
bind = SUPER, Q, killactive,
bind = SUPER, M, exit,
bind = SUPER, E, exec, yazi
bind = SUPER, Space, exec, fuzzel
bind = SUPER, F, fullscreen,

# Window focus
bind = SUPER, left, movefocus, l
bind = SUPER, right, movefocus, r
bind = SUPER, up, movefocus, u
bind = SUPER, down, movefocus, d

# Workspaces
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5
bind = SUPER, SHIFT, 1, movetoworkspace, 1
bind = SUPER, SHIFT, 2, movetoworkspace, 2
bind = SUPER, SHIFT, 3, movetoworkspace, 3
bind = SUPER, SHIFT, 4, movetoworkspace, 4
bind = SUPER, SHIFT, 5, movetoworkspace, 5

# Screenshot
bind = , Print, exec, grim -g "$(slurp)" - | swappy -f -

# Autostart
exec-once = waybar
exec-once = mako
exec-once = hypridle
exec-once = hyprpaper
EOF
      echo "  [ok] $hypr_conf (minimal config written — Hyprland example not found)"
    fi
  fi
}

# ── Waybar: create config dirs (both WMs share waybar) ───────────────────────

configure_waybar() {
  mkdir -p "$HOME/.config/waybar"
  if [[ ! -f "$HOME/.config/waybar/config.jsonc" ]]; then
    # Copy system default if available
    for candidate in \
      /etc/waybar/config \
      /usr/share/waybar/config.jsonc \
      /usr/share/doc/waybar/examples/config; do
      if [[ -f "$candidate" ]]; then
        cp "$candidate" "$HOME/.config/waybar/config.jsonc"
        echo "  [ok] ~/.config/waybar/config.jsonc (copied from $candidate)"
        return
      fi
    done
    echo "  [info] waybar example config not found — waybar will use its built-in defaults"
  else
    echo "  [skip] ~/.config/waybar/config.jsonc already exists"
  fi
}

# ── Mako: create config dir ───────────────────────────────────────────────────

configure_mako() {
  mkdir -p "$HOME/.config/mako"
  if [[ ! -f "$HOME/.config/mako/config" ]]; then
    cat > "$HOME/.config/mako/config" <<'EOF'
# Mako notification daemon config
# See: man 5 mako

font=monospace 11
background-color=#2e3440
text-color=#eceff4
border-color=#5e81ac
border-radius=6
default-timeout=5000
max-visible=5
sort=-time
EOF
    echo "  [ok] ~/.config/mako/config"
  else
    echo "  [skip] ~/.config/mako/config already exists"
  fi
}

# ── Run all ───────────────────────────────────────────────────────────────────

echo "==> Configuring VS Code for native Wayland..."
configure_vscode

echo "==> Configuring Chromium for native Wayland..."
configure_chromium

echo "==> Setting up Sway config..."
configure_sway

echo "==> Setting up Hyprland config..."
configure_hyprland

echo "==> Setting up Waybar config..."
configure_waybar

echo "==> Setting up Mako config..."
configure_mako

echo ""
echo "==> Configuration complete."
echo "    Next: run 05-verify.sh"
