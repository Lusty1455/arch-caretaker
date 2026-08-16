#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

test -x "$repo_root/scripts/build-niri-taskbar.sh" || {
    echo 'FAIL: missing taskbar builder' >&2
    exit 1
}

rg -Fq 'cargo build --release' "$repo_root/scripts/build-niri-taskbar.sh" || {
    echo 'FAIL: release build missing' >&2
    exit 1
}

printf 'PASS: taskbar builder is defined\n'
