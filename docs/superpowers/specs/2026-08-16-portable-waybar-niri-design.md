# Portable Waybar and Niri Configuration Design

## Goal

Make the user's Waybar configuration reproducible on a freshly installed Arch
Linux desktop with Niri.  A normal user should be able to copy this repository
to the new machine and run one user-facing installer to obtain the same
Waybar layout, enabled controls, scripts, Niri startup integration, and Niri
Taskbar plugin.

The installer must never require a password in a terminal.  It uses `pkexec`
when installing official packages so Polkit presents an authentication dialog.

## Scope

The migration includes all existing, recoverable Waybar behavior:

- Bar layout, modules, style, color definitions, and image assets.
- Waybar helper scripts: screenshots, long screenshots, recording, Bluetooth,
  update status, command center, and Super Productivity integration.
- Niri configuration and the `swayidle` startup script that supports the
  Waybar idle-inhibitor control.
- The Niri Taskbar Waybar CFFI plugin, built locally from its retained source.
- Official-package, AUR-package, and Python dependency manifests.
- Deployment, installation, and verification scripts.

The following actions are deliberately out of scope because their source files
are absent from the current machine and their intended behavior cannot be
recovered reliably:

- `matugen-select-type.sh`
- `niri_auto_blur_bg.sh`
- `random-anime-wallpaper.sh`
- `toggle-wlsunset`

The corresponding Waybar actions will be removed from the tracked portable
configuration, rather than retained as broken controls.

## Repository Layout

```text
arch-caretaker/
  desktop/
    waybar/                 # Canonical Waybar config, assets, and scripts
    niri/                   # Canonical Niri config, swayidle, desktop entry
    niri-taskbar/           # Pinned source and MIT license for the plugin
  packages/
    pacman.txt              # Official Arch package names
    aur.txt                 # AUR package names
    python-longshot.txt     # Pinned Python requirements for image stitching
  scripts/
    install.sh              # Install prerequisites, deploy, build, validate
    deploy.sh               # Copy canonical config into XDG config directories
    build-niri-taskbar.sh   # Build the CFFI dynamic library for this Niri ABI
    verify.sh               # Static and runtime prerequisite checks
  tests/                    # Focused noninteractive checks
```

Canonical configuration is stored in the repository, not in `~/.config`.
Deployment copies it into `~/.config/waybar` and `~/.config/niri`, so the
result continues working if the repository is moved or deleted. Before an
existing target is replaced, `deploy.sh` saves it under the repository's
ignored `backup/` directory with a timestamp.

## Installation Flow

```text
repository copy
     |
     v
scripts/install.sh
     |
     +-- install pacman packages through pkexec
     +-- ensure the configured AUR helper can install aur.txt
     +-- create the longshot virtual environment from requirements
     +-- build and install the Niri Taskbar library under ~/.local/lib/waybar
     +-- deploy Waybar and Niri files
     `-- run scripts/verify.sh and reload Waybar/Niri when available
```

The Python virtual environment is not versioned. It contains `numpy` and
OpenCV binaries for long-screenshot stitching and is approximately 270 MB on
this machine. `install.sh` recreates it from `packages/python-longshot.txt`.

The Niri Taskbar library is architecture- and Niri-version-dependent. The
repository retains its source and license; `build-niri-taskbar.sh` builds the
shared library locally. The installer renders the current user's home path
into the deployed Waybar module configuration instead of committing a
machine-specific `/home/kael` path.

## Dependency Policy

`packages/pacman.txt` contains official components such as Niri, Waybar,
Rofi, Kitty, PipeWire/WirePlumber, `swayidle`, `swaylock-effects`, `hyprpicker`,
recording/screenshot tools, and the Rust/Python build toolchains.

`packages/aur.txt` records components currently supplied outside the official
repositories, including `shorin-contrib-git`, `shorinclip-git`, and
`super-productivity`. The installer detects an AUR helper before attempting
that stage and reports a precise prerequisite if none is available. It will
not silently omit those features.

Hardware-specific integrations remain guarded by command and hardware checks:
for example `ddcutil` actions only work with a compatible external display,
and the command center exposes Btrfs actions only on a Btrfs system.

## Verification

`scripts/verify.sh` will check:

1. Every executable reference in the tracked Waybar and Niri configuration.
2. Shell syntax and executable bits for managed scripts.
3. JSONC/KDL configuration validity where the installed tools support it.
4. The compiled Niri Taskbar library exists at the rendered module path.
5. Longshot's Python dependencies can import from its recreated environment.
6. Existing desktop button and Super Productivity tests.

On the current desktop, acceptance additionally reloads Niri configuration,
restarts Waybar, and verifies that it starts without missing managed files.
Interactive behavior requiring hardware or a GUI application is reported as
such rather than inferred from static checks.

### 2026-08-16 Verification Evidence

The portability, desktop-button, manifest, plugin-builder, deployment,
verification, and installer-contract tests all passed. Deployment was also run
against the active user's configuration after creating timestamped backups.
The Niri Taskbar library was built from the retained source, and the deployed
longshot environment successfully imported both `cv2` and `numpy`.

`niri msg action load-config-file` accepted the deployed configuration. Waybar
was restarted through Niri and its process was present; the user journal
contained no Waybar or Niri Taskbar errors from that restart.

## Safety and Version Control

No tokens, credentials, logs, caches, Python virtual environments, recordings,
or machine-private backup files are tracked. The repository keeps deployment
source only. After migration and verification, the work is suitable for an
initial local Git commit; publishing to GitHub remains a separate explicit
action once a destination repository is selected.
