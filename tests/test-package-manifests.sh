#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

for manifest in pacman.txt aur.txt python-longshot.txt; do
    path="$repo_root/packages/$manifest"
    test -s "$path" || fail "missing manifest: $manifest"

    entries=$(rg -v '^#' "$path")
    test "$(printf '%s\n' "$entries" | sort -u | wc -l)" -eq \
        "$(printf '%s\n' "$entries" | wc -l)" || \
        fail "duplicate entry: $manifest"
done

rg -Fxq 'waybar' "$repo_root/packages/pacman.txt" || fail 'waybar missing'
rg -Fxq 'shorin-contrib-git' "$repo_root/packages/aur.txt" || fail 'shorin missing'

printf 'PASS: package manifests are valid\n'
