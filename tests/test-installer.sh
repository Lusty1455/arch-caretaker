#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

test -x "$repo_root/scripts/install.sh" || {
    echo 'FAIL: missing installer' >&2
    exit 1
}

rg -Fq 'pkexec pacman' "$repo_root/scripts/install.sh" || {
    echo 'FAIL: pkexec pacman missing' >&2
    exit 1
}

rg -Fq 'setup-longshot.sh' "$repo_root/scripts/install.sh" || {
    echo 'FAIL: longshot setup missing' >&2
    exit 1
}

rg -Fq 'build-niri-taskbar.sh' "$repo_root/scripts/install.sh" || {
    echo 'FAIL: plugin build missing' >&2
    exit 1
}

printf 'PASS: installer contract is valid\n'
