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
`sway` · `swaylock` · `swayidle` · `waybar` · `fuzzel` · `foot` · `mako` · `grim` · `slurp` · `wl-clipboard` · `cliphist` · `wlsunset` · `kanshi` · `xdg-desktop-portal-wlr` · `brightnessctl` · `playerctl`

### Hyprland stack (via `ppa:cppiber/hyprland`)
`hyprland` · `hyprlock` · `hypridle` · `hyprpaper` · `hyprsunset` · `hyprpicker` · `xdg-desktop-portal-hyprland` · `hyprpolkitagent` · `hyprsysteminfo` · `hyprpwcenter` · `hyprshutdown` · `waybar` · `fuzzel` · `kitty` · `mako`

### Shared tools
`yazi` (Wayland-native terminal file manager, written in Rust) · `grim` · `slurp` · `wl-clipboard` · `cliphist` · `xwayland` (passive fallback for legacy apps)

### Noctalia desktop shell (optional — built from source)
`noctalia` — a native C++23 / OpenGL ES Wayland desktop shell (bars, dock, launcher, notifications, lock screen, wallpaper, control center) that runs **on top of** Sway or Hyprland. No Qt/GTK, no Quickshell. Ships nothing prebuilt for Ubuntu 24.04, so `06-install-noctalia.sh` builds it (and WirePlumber 0.5) from source.

## Scripts

Run in order as your **normal user** (scripts call `sudo` internally where needed):

```bash
bash 01-install-sway.sh       # Sway + companion stack (apt, no PPA)
bash 02-install-hyprland.sh   # Hyprland + ecosystem (cppiber PPA)
bash 03-install-yazi.sh       # Yazi file manager + preview deps
bash 04-configure.sh          # Config files, Wayland flags, starter configs
bash 06-install-noctalia.sh   # (optional) Noctalia desktop shell from source
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
| `Super + Space` | App launcher (Noctalia launcher if installed, else fuzzel) |
| `Super + E` | File manager (yazi in kitty) |
| `Super + Q` | Close window |
| `Super + F` | Fullscreen |
| `Super + 1–9` | Switch workspace |
| `Super + Shift + 1–9` | Move window to workspace |
| `Super + V` | Clipboard picker (cliphist) |
| `Super + =` | Increase cursor zoom |
| `Super + -` | Decrease cursor zoom |
| `Super + 0` | Reset cursor zoom |
| `Print` | Screenshot region → clipboard |
| `Shift + Print` | Screenshot fullscreen → ~/Pictures |

Sway keybindings are documented in `~/.config/sway/config` (heavily commented system default).

## Hyprland PPA note

Hyprland is not in Ubuntu 24.04 official repos (added only in Ubuntu 25.04).
This setup uses `ppa:cppiber/hyprland` — actively maintained, pre-compiled for Noble, ships the full `hypr*` ecosystem as proper apt packages. Hyprland updates appear in Update Manager like any other package; no special steps needed before `apt upgrade` (unlike sysext-based installs).

## Hyprland config note

The generated starter config now uses a modern Lua file at `~/.config/hypr/hyprland.lua`. Hyprland 0.55+ prefers Lua for new features and keeps the old `.conf` syntax as a legacy path. The setup still works with the older syntax if you already have a custom config, but new features are wired through the Lua starter.

## File manager

**Yazi** is the primary file manager — Rust-based, terminal-native, Wayland-clean, rich previews (images, video thumbnails, PDFs) inside foot/kitty. Launch with `yazi`.

Nemo (Mint's default) remains installed and works via XWayland when needed.

## Noctalia desktop shell

**Noctalia** (v5) is a native Wayland *desktop shell* — one integrated layer that owns the bars, dock, launcher, control center, notifications, wallpaper, lock screen, session panel, OSDs, and system-tray. It is built directly on Wayland + OpenGL ES with **no Qt, GTK, or Quickshell dependency**, and it runs on top of your existing Sway or Hyprland compositor. Install it with `06-install-noctalia.sh`.

### Why it is built from source

Noctalia v5 has no prebuilt package for Ubuntu 24.04 Noble (their APT repo only targets Debian Trixie/Sid and Ubuntu 26.04). The script builds it from source and handles two dependencies that are newer than Ubuntu 24.04 ships:

| Gap | How `06` handles it |
|---|---|
| **WirePlumber 0.5** (Ubuntu has only 0.4) | Built from source into `/usr/local`. The apt-managed 0.4 stays the audio session manager; Noctalia only links the 0.5 client library, so audio is not disrupted. |
| **stb** — `stb_image_resize2.h` missing | The two required header-only files are vendored into `/usr/local/include/stb`. |

The modern **PipeWire 1.2**, **sdbus-c++ 2.x**, and **wayland-protocols 1.49** that Noctalia v5 requires come from the `cppiber` PPA (the same one `02-install-hyprland.sh` adds); `06` ensures that PPA is present, so it works even if you only installed Sway.

### Conflict with mako — handled automatically on Hyprland

Noctalia registers `org.freedesktop.Notifications` and `org.kde.StatusNotifierWatcher` (its own notification daemon and tray host), so it **must not run alongside `mako`** (installed by scripts 01/02) or the two fight over those D-Bus names.

The Hyprland autostart written by `04-configure.sh` now auto-detects this: if `noctalia` is on `PATH` it starts Noctalia (which provides the bar + notifications) and skips waybar + mako; otherwise it falls back to waybar + mako as before. No manual editing needed.

On **Sway**, the generated config does not autostart mako, and Noctalia claims the notification name first, so there is no conflict — just add the autostart line below.

### Autostarting the shell

On Hyprland this is automatic (see above) once Noctalia is installed. On Sway, add:

```bash
# Sway — ~/.config/sway/config
exec noctalia --daemon
```

Control a running instance with `noctalia msg ...`. Config lives in `~/.config/noctalia/`.

## Adding / removing a session

To temporarily stop using a session without uninstalling it, move its `.desktop` file:

```bash
# Hide Hyprland from LightDM
sudo mv /usr/share/wayland-sessions/hyprland.desktop /usr/share/wayland-sessions/hyprland.desktop.disabled

# Restore it
sudo mv /usr/share/wayland-sessions/hyprland.desktop.disabled /usr/share/wayland-sessions/hyprland.desktop
```
