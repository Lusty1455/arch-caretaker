# Portable Waybar and Niri Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the current recoverable Waybar and Niri setup deployable on a freshly installed Arch Linux Niri desktop through one installer.

**Architecture:** Canonical Waybar/Niri sources live in this repository and are copied into XDG configuration directories during deployment. Package manifests, local plugin compilation, and the long-screenshot virtual environment are separate installation stages.

**Tech Stack:** Bash, Waybar JSONC, Niri KDL, Arch pacman/AUR, pkexec, Cargo, Python venv.

**Spec:** `docs/superpowers/specs/2026-08-16-portable-waybar-niri-design.md`

## Global Constraints

- Use `pkexec` for pacman. Never request or handle a password in a terminal.
- Copy sources into `~/.config`; do not leave deployable configuration dependent on repository paths.
- Do not track caches, backups, recordings, the Python virtual environment, built libraries, or machine-private state.
- Remove actions backed by the unavailable `matugen-select-type.sh`, `niri_auto_blur_bg.sh`, `random-anime-wallpaper.sh`, and `toggle-wlsunset`.
- Retain every other recoverable Waybar control.
- Do not retain `/home/kael` in portable configuration. Render the installing user's home path at deployment.
- Deployment backs up an existing target with `mv`; it must not recursively delete a configuration directory.

---

### Task 1: Test and Migrate Canonical Configuration

**Files:**
- Create: `desktop/waybar/{config.jsonc,modules.jsonc,modules-dividers.jsonc,style.css,colors.css,logo/bluetooth.png}`
- Create: `desktop/waybar/scripts/*` excluding `longshot-sh/venv/`
- Create: `desktop/niri/config.kdl`
- Create: `tests/test-portable-waybar.sh`

**Interfaces:**
- Consumes: current `~/.config/waybar` and `~/.config/niri/config.kdl`.
- Produces: a canonical source tree and a test that rejects missing sources, excluded actions, and host paths.

- [ ] **Step 1: Write the failing test**

Create `tests/test-portable-waybar.sh`:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
test -f "$root/desktop/waybar/config.jsonc" || fail 'missing canonical Waybar config'
test -f "$root/desktop/waybar/modules.jsonc" || fail 'missing canonical Waybar modules'
test -f "$root/desktop/niri/config.kdl" || fail 'missing canonical Niri config'
for name in matugen-select-type.sh niri_auto_blur_bg.sh random-anime-wallpaper.sh toggle-wlsunset; do
  ! rg -Fq "$name" "$root/desktop/waybar/modules.jsonc" || fail "unavailable action retained: $name"
done
! rg -Fq '/home/kael' "$root/desktop/waybar" "$root/desktop/niri/config.kdl" || fail 'machine-specific path retained'
printf 'PASS: portable Waybar sources are valid\n'
```

- [ ] **Step 2: Verify red**

Run: `chmod 755 tests/test-portable-waybar.sh && tests/test-portable-waybar.sh`

Expected: `FAIL: missing canonical Waybar config`.

- [ ] **Step 3: Migrate source files**

Run:

```bash
rsync -a --delete --exclude 'scripts/longshot-sh/venv/' "$HOME/.config/waybar/" desktop/waybar/
cp "$HOME/.config/niri/config.kdl" desktop/niri/config.kdl
find desktop/waybar/scripts -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod 755 {} +
```

Remove the four unavailable click handlers from `desktop/waybar/modules.jsonc`. Replace its Taskbar `module_path` with `@HOME@/.local/lib/waybar/libniri_taskbar_current_workspace.so`.

- [ ] **Step 4: Verify green**

Run: `tests/test-portable-waybar.sh && tests/test-desktop-buttons.sh`

Expected: both tests exit 0.

- [ ] **Step 5: Commit**

```bash
git add desktop/waybar desktop/niri/config.kdl tests/test-portable-waybar.sh
git commit -m "feat: add portable Waybar and Niri sources"
```

### Task 2: Define Dependency and Build Sources

**Files:**
- Create: `packages/pacman.txt`
- Create: `packages/aur.txt`
- Create: `packages/python-longshot.txt`
- Create: `desktop/niri-taskbar/*`
- Create: `tests/test-package-manifests.sh`

**Interfaces:**
- Consumes: newline-delimited package manifests and retained Niri Taskbar source.
- Produces: reproducible official/AUR/Python dependency inputs and plugin source with its MIT license.

- [ ] **Step 1: Write the failing manifest test**

Create `tests/test-package-manifests.sh`:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
for file in pacman.txt aur.txt python-longshot.txt; do
  path="$root/packages/$file"
  test -s "$path" || fail "missing manifest: $file"
  entries=$(rg -v '^#' "$path")
  test "$(printf '%s\n' "$entries" | sort -u | wc -l)" -eq "$(printf '%s\n' "$entries" | wc -l)" || fail "duplicate entry: $file"
done
rg -Fxq waybar "$root/packages/pacman.txt" || fail 'waybar missing'
rg -Fxq shorin-contrib-git "$root/packages/aur.txt" || fail 'shorin missing'
```

- [ ] **Step 2: Verify red**

Run: `chmod 755 tests/test-package-manifests.sh && tests/test-package-manifests.sh`

Expected: `FAIL: missing manifest: pacman.txt`.

- [ ] **Step 3: Create exact manifests and vendor the plugin**

`pacman.txt` contains one package per line: `niri`, `waybar`, `rofi`, `kitty`, `swaylock-effects`, `swayidle`, `hyprpicker`, `wf-recorder`, `grim`, `slurp`, `wl-clipboard`, `imagemagick`, `python`, `python-pip`, `ffmpeg`, `swappy`, `cliphist`, `mako`, `networkmanager`, `gnome-clocks`, `gnome-calendar`, `ddcutil`, `pipewire`, `wireplumber`, `rust`, `base-devel`, and `git`.

`aur.txt` contains: `shorin-contrib-git`, `shorinclip-git`, `super-productivity`, `satty`, `swayosd`, `swaync`, `pavucontrol`, `bluetui`, `impala`, `waypaper`, `wlogout`, and `matugen`.

`python-longshot.txt` contains `numpy` and `opencv-python`.

Vendor plugin source without Git metadata:

```bash
rsync -a --delete --exclude .git/ --exclude .worktrees/ /home/kael/arch-codex/projects/niri-taskbar/ desktop/niri-taskbar/
```

- [ ] **Step 4: Verify green and commit**

Run: `tests/test-package-manifests.sh`

Then:

```bash
git add packages desktop/niri-taskbar tests/test-package-manifests.sh
git commit -m "feat: define desktop dependencies and taskbar source"
```

### Task 3: Implement Plugin Build and Copy Deployment

**Files:**
- Create: `scripts/build-niri-taskbar.sh`
- Create: `scripts/deploy.sh`
- Create: `tests/test-niri-taskbar-build.sh`
- Create: `tests/test-deploy.sh`
- Modify: `.gitignore`

**Interfaces:**
- `build-niri-taskbar.sh` accepts `NIRI_TASKBAR_DEST`, defaulting to `$HOME/.local/lib/waybar/libniri_taskbar_current_workspace.so`.
- `deploy.sh` accepts `XDG_CONFIG_HOME` and `ARCH_CARETAKER_BACKUP_DIR`.
- Deployment produces copied `waybar/` and `niri/` trees and replaces `@HOME@` only in deployed files.

- [ ] **Step 1: Write failing tests**

Create `tests/test-niri-taskbar-build.sh`:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test -x "$root/scripts/build-niri-taskbar.sh" || { echo 'FAIL: missing taskbar builder' >&2; exit 1; }
rg -Fq 'cargo build --release' "$root/scripts/build-niri-taskbar.sh" || { echo 'FAIL: release build missing' >&2; exit 1; }
```

Create `tests/test-deploy.sh`:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
XDG_CONFIG_HOME="$tmp/config" ARCH_CARETAKER_BACKUP_DIR="$tmp/backups" "$root/scripts/deploy.sh"
test -f "$tmp/config/waybar/config.jsonc"
test -f "$tmp/config/niri/config.kdl"
! test -L "$tmp/config/waybar"
! rg -Fq '@HOME@' "$tmp/config/waybar/modules.jsonc"
```

- [ ] **Step 2: Verify red**

Run: `tests/test-niri-taskbar-build.sh; tests/test-deploy.sh`

Expected: both fail because their scripts do not exist.

- [ ] **Step 3: Implement the minimal scripts**

`scripts/build-niri-taskbar.sh` is:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
dest=${NIRI_TASKBAR_DEST:-"$HOME/.local/lib/waybar/libniri_taskbar_current_workspace.so"}
cd "$root/desktop/niri-taskbar"
cargo build --release
install -Dm755 target/release/libniri_taskbar.so "$dest"
```

`scripts/deploy.sh` creates target and backup directories, moves an existing target to `$ARCH_CARETAKER_BACKUP_DIR/<component>-<UTC timestamp>`, copies with `rsync -a --delete`, and uses a literal-safe `sed` replacement for `@HOME@`. It deploys `desktop/waybar` and `desktop/niri`, but does not deploy `desktop/niri-taskbar`.

Append:

```gitignore
desktop/waybar/scripts/longshot-sh/venv/
desktop/niri-taskbar/target/
*.so
```

to `.gitignore`.

- [ ] **Step 4: Verify green**

Run:

```bash
tests/test-niri-taskbar-build.sh
tests/test-deploy.sh
NIRI_TASKBAR_DEST=/tmp/arch-caretaker-taskbar.so scripts/build-niri-taskbar.sh
test -s /tmp/arch-caretaker-taskbar.so
```

- [ ] **Step 5: Commit**

```bash
git add scripts/build-niri-taskbar.sh scripts/deploy.sh tests/test-niri-taskbar-build.sh tests/test-deploy.sh .gitignore
git commit -m "feat: build taskbar plugin and deploy config"
```

### Task 4: Add Longshot Setup and End-to-End Verification

**Files:**
- Create: `scripts/setup-longshot.sh`
- Create: `scripts/verify.sh`
- Create: `tests/test-verify.sh`

**Interfaces:**
- `setup-longshot.sh` creates only `desktop/waybar/scripts/longshot-sh/venv` and installs the Python manifest there.
- `verify.sh` validates sources, deployed configuration, managed shell syntax, the rendered Taskbar plugin path, and all noninteractive tests.

- [ ] **Step 1: Write a failing verification test**

Create `tests/test-verify.sh`:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
XDG_CONFIG_HOME="$tmp/config" ARCH_CARETAKER_BACKUP_DIR="$tmp/backups" "$root/scripts/deploy.sh"
if HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/config" "$root/scripts/verify.sh"; then
  echo 'FAIL: verification accepted missing plugin' >&2
  exit 1
fi
```

- [ ] **Step 2: Verify red**

Run: `tests/test-verify.sh`

Expected: failure because `scripts/verify.sh` does not exist.

- [ ] **Step 3: Implement setup and verification**

`setup-longshot.sh` runs:

```bash
python3 -m venv "$root/desktop/waybar/scripts/longshot-sh/venv"
"$root/desktop/waybar/scripts/longshot-sh/venv/bin/pip" install -r "$root/packages/python-longshot.txt"
```

`verify.sh` must: run the three static tests; run `bash -n` on every managed shell script; check every managed script is executable; reject excluded action names; require `$HOME/.local/lib/waybar/libniri_taskbar_current_workspace.so`; and confirm `@HOME@` is absent from deployed modules.

- [ ] **Step 4: Verify green**

Create the temporary plugin with `NIRI_TASKBAR_DEST="$tmp/home/.local/lib/waybar/libniri_taskbar_current_workspace.so" scripts/build-niri-taskbar.sh`, then run `HOME="$tmp/home" XDG_CONFIG_HOME="$tmp/config" scripts/verify.sh`.

Expected: exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/setup-longshot.sh scripts/verify.sh tests/test-verify.sh
git commit -m "feat: verify portable desktop deployment"
```

### Task 5: Build the User Installer and Perform Live Validation

**Files:**
- Create: `scripts/install.sh`
- Create: `tests/test-installer.sh`
- Modify: `README.md`
- Modify: spec and this plan with verification evidence

**Interfaces:**
- `install.sh --all` runs package installation, AUR installation, longshot setup, taskbar build, deployment, and verification in that order.
- It supports `--packages`, `--aur`, `--longshot`, `--build-plugin`, `--deploy`, `--verify`, and `--help`.

- [ ] **Step 1: Write the failing installer test**

Create `tests/test-installer.sh`:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test -x "$root/scripts/install.sh" || { echo 'FAIL: missing installer' >&2; exit 1; }
rg -Fq 'pkexec pacman' "$root/scripts/install.sh" || { echo 'FAIL: pkexec pacman missing' >&2; exit 1; }
rg -Fq 'setup-longshot.sh' "$root/scripts/install.sh" || { echo 'FAIL: longshot setup missing' >&2; exit 1; }
rg -Fq 'build-niri-taskbar.sh' "$root/scripts/install.sh" || { echo 'FAIL: plugin build missing' >&2; exit 1; }
```

- [ ] **Step 2: Verify red**

Run: `tests/test-installer.sh`

Expected: `FAIL: missing installer`.

- [ ] **Step 3: Implement installer and README**

`install.sh` reads noncomment package names to arrays, executes official packages with `pkexec pacman -S --needed "${packages[@]}"`, requires `paru` for `--aur` and says `Install paru first, then rerun scripts/install.sh --aur` if absent. Its default is `--all`. It never calls `sudo`.

Document `scripts/install.sh`, the Polkit prompt, the one-time `paru` prerequisite, the four excluded actions, and that hardware-specific buttons require compatible hardware.

- [ ] **Step 4: Verify green**

Run: `tests/test-installer.sh && scripts/install.sh --help`

Expected: exit 0 and help without installation side effects.

- [ ] **Step 5: Run full tests and current-desktop verification**

Run:

```bash
tests/test-portable-waybar.sh
tests/test-desktop-buttons.sh
tests/test-package-manifests.sh
tests/test-niri-taskbar-build.sh
tests/test-deploy.sh
tests/test-verify.sh
tests/test-installer.sh
scripts/deploy.sh
scripts/build-niri-taskbar.sh
scripts/verify.sh
niri msg action load-config-file
```

Restart Waybar in the graphical Niri session, then inspect its user journal for managed-file errors. Record only observed interaction checks.

- [ ] **Step 6: Commit and offer GitHub publication**

After the user supplies a Git identity, run `git add . && git diff --cached --check && git commit -m "feat: add portable Arch desktop configuration"`. Report the commit hash and ask for a specific GitHub destination before creating a remote or pushing.

