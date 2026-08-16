#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

XDG_CONFIG_HOME="$test_root/config" \
ARCH_CARETAKER_BACKUP_DIR="$test_root/backups" \
"$repo_root/scripts/deploy.sh"

test -f "$test_root/config/waybar/config.jsonc"
test -f "$test_root/config/niri/config.kdl"
! test -L "$test_root/config/waybar"
! rg -Fq '@HOME@' "$test_root/config/waybar/modules.jsonc"

printf 'PASS: deployment copies portable configuration\n'
