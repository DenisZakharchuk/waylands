# Wayland DE Setup — Linux Mint 22.x

Install Sway and Hyprland alongside Cinnamon on Linux Mint 22.x (Ubuntu 24.04 Noble base).
All three sessions coexist at the LightDM login screen — select one at boot.

## System requirements

- Linux Mint 22.x (Wilma / Xia / Zara / Zena) — Ubuntu 24.04 Noble base
- Any GPU (AMD/Intel integrated works perfectly; NVIDIA requires drivers ≥525)

## What gets installed

### Sessions (selectable at LightDM login)
| Session | Type | Notes |
|---|---|---|
| **Cinnamon** | X11 | Pre-existing, untouched |
| **Sway** | Wayland | Keyboard-driven tiling WM, minimal, rock-solid |
| **Hyprland** | Wayland | Dynamic tiling, animated, visual polish |

### Sway stack (all from official Ubuntu 24.04 repos)
`sway` · `swaylock` · `swayidle` · `waybar` · `fuzzel` · `foot` · `mako` · `grim` · `slurp` · `swappy` · `wl-clipboard` · `cliphist` · `wlsunset` · `kanshi` · `xdg-desktop-portal-wlr` · `brightnessctl` · `playerctl`

### Hyprland stack (via `ppa:cppiber/hyprland`)
`hyprland` · `hyprlock` · `hypridle` · `hyprpaper` · `hyprsunset` · `hyprpicker` · `xdg-desktop-portal-hyprland` · `waybar` · `fuzzel` · `kitty` · `mako`

### Shared tools
`yazi` (Wayland-native terminal file manager, written in Rust) · `grim` · `slurp` · `swappy` · `wl-clipboard` · `cliphist` · `xwayland` (passive fallback for legacy apps)

## Scripts

Run in order as your **normal user** (scripts call `sudo` internally where needed):

```bash
bash 01-install-sway.sh       # Sway + companion stack (apt, no PPA)
bash 02-install-hyprland.sh   # Hyprland + ecosystem (cppiber PPA)
bash 03-install-yazi.sh       # Yazi file manager + preview deps
bash 04-configure.sh          # Config files, Wayland flags, starter configs
bash 05-verify.sh             # Sanity check — confirms all sessions and tools
```

> **Do not run scripts 04 and 05 as root / inside `sudo -i`.**
> They write to `$HOME/.config/` — running as root would place files in `/root/.config/` instead of your user home.

After `05-verify.sh` passes: **reboot → select session at LightDM login screen (gear icon).**

## Wayland-native app config

Scripts 04 sets these automatically. Listed here for reference.

**VS Code** — `~/.config/code-flags.conf`:
```
--ozone-platform=wayland
--enable-features=WaylandWindowDecorations
```

**Chromium** — `~/.config/chromium-flags.conf`:
```
--ozone-platform=wayland
```

XWayland remains installed as a passive fallback for apps that have no Wayland backend (Wine, some Java GUIs, etc.). It activates automatically when needed and is invisible to the user.

## Key bindings (Hyprland)

| Key | Action |
|---|---|
| `Super + Enter` | Terminal (kitty) |
| `Super + Space` | App launcher (fuzzel) |
| `Super + E` | File manager (yazi in kitty) |
| `Super + Q` | Close window |
| `Super + F` | Fullscreen |
| `Super + 1–5` | Switch workspace |
| `Super + Shift + 1–5` | Move window to workspace |
| `Print` | Screenshot region → swappy |

Sway keybindings are documented in `~/.config/sway/config` (heavily commented system default).

## Hyprland PPA note

Hyprland is not in Ubuntu 24.04 official repos (added only in Ubuntu 25.04).
This setup uses `ppa:cppiber/hyprland` — actively maintained, pre-compiled for Noble, ships the full `hypr*` ecosystem as proper apt packages. Hyprland updates appear in Update Manager like any other package; no special steps needed before `apt upgrade` (unlike sysext-based installs).

## File manager

**Yazi** is the primary file manager — Rust-based, terminal-native, Wayland-clean, rich previews (images, video thumbnails, PDFs) inside foot/kitty. Launch with `yazi`.

Nemo (Mint's default) remains installed and works via XWayland when needed.

## Adding / removing a session

To temporarily stop using a session without uninstalling it, move its `.desktop` file:

```bash
# Hide Hyprland from LightDM
sudo mv /usr/share/wayland-sessions/hyprland.desktop /usr/share/wayland-sessions/hyprland.desktop.disabled

# Restore it
sudo mv /usr/share/wayland-sessions/hyprland.desktop.disabled /usr/share/wayland-sessions/hyprland.desktop
```
