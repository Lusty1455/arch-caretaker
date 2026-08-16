#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
waybar_dir="$repo_root/desktop/waybar"
niri_config="$repo_root/desktop/niri/config.kdl"

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

test -f "$waybar_dir/config.jsonc" || fail 'missing canonical Waybar config'
test -f "$waybar_dir/modules.jsonc" || fail 'missing canonical Waybar modules'
test -f "$niri_config" || fail 'missing canonical Niri config'

for unavailable_action in \
    matugen-select-type.sh \
    niri_auto_blur_bg.sh \
    random-anime-wallpaper.sh \
    toggle-wlsunset; do
    ! rg -Fq "$unavailable_action" "$waybar_dir/modules.jsonc" || \
        fail "unavailable action retained: $unavailable_action"
done

! rg -Fq '/home/kael' "$waybar_dir" "$niri_config" || \
    fail 'machine-specific home path retained'

printf 'PASS: portable Waybar sources are valid\n'
