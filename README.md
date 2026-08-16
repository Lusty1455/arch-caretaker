# Arch Caretaker

User-owned, reproducible configuration for this Arch Linux desktop.

## Areas

- `statusbar/`: status-bar configuration and helper scripts
- `shell/`: shell configuration and prompt tooling
- `desktop/`: desktop-session and window-manager configuration
- `terminal/`: terminal emulator configuration
- `packages/`: package manifests and installation notes
- `backup/`: ignored local backup staging area

System changes are opt-in and require explicit confirmation.
User-level deployment copies canonical files, so the deployed desktop works even
if this checkout is moved or removed.

## Portable Waybar and Niri

On a fresh Arch Linux Niri installation, run:

```bash
scripts/install.sh
```

The official package stage uses a graphical Polkit prompt through `pkexec`; it
never requests a password in the terminal. Install `paru` once before running
the AUR stage. Use `scripts/install.sh --help` to run a single stage.

Four previously configured actions are intentionally excluded because their
source was absent: Matugen scheme selection, automatic Niri background blur,
random anime wallpapers, and the wlsunset toggle. Hardware-specific controls,
such as external-monitor brightness, still require compatible hardware.
