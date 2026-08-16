#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d)
trap 'rm -rf "$test_root"' EXIT

test -x "$repo_root/scripts/verify.sh" || {
    echo 'FAIL: missing verification script' >&2
    exit 1
}

HOME="$test_root/home" \
XDG_CONFIG_HOME="$test_root/config" \
ARCH_CARETAKER_BACKUP_DIR="$test_root/backups" \
"$repo_root/scripts/deploy.sh" >/dev/null

if HOME="$test_root/home" XDG_CONFIG_HOME="$test_root/config" \
    "$repo_root/scripts/verify.sh"; then
    echo 'FAIL: verification accepted missing plugin' >&2
    exit 1
fi

printf 'PASS: verification rejects a missing plugin\n'
