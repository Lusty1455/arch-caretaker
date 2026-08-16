#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
idle_script="$repo_root/desktop/niri/swayidle.sh"
packages_file="$repo_root/packages/desktop-buttons.txt"
desktop_file="$repo_root/desktop/applications/swaylock.desktop"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

[[ -x "$idle_script" ]] || fail "missing executable swayidle script"
grep -Fq 'swayidle -w' "$idle_script" || fail "swayidle script must wait for the compositor"
grep -Fq 'swaylock' "$idle_script" || fail "swayidle script must lock the session"

[[ -f "$packages_file" ]] || fail "missing desktop button package manifest"
grep -Fxq 'hyprpicker' "$packages_file" || fail "hyprpicker is not declared"
grep -Fxq 'swayidle' "$packages_file" || fail "swayidle is not declared"

[[ -f "$desktop_file" ]] || fail "missing swaylock desktop entry"
grep -Fxq 'Exec=swaylock' "$desktop_file" || fail "desktop entry must launch swaylock"
grep -Fxq 'Terminal=false' "$desktop_file" || fail "desktop entry must not open a terminal"

printf 'PASS: desktop button requirements are declared\n'
