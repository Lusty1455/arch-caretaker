#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
waybar_config="$config_home/waybar/modules.jsonc"
plugin_path="$HOME/.local/lib/waybar/libniri_taskbar_current_workspace.so"

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

"$repo_root/tests/test-portable-waybar.sh"
"$repo_root/tests/test-desktop-buttons.sh"
"$repo_root/tests/test-package-manifests.sh"

while IFS= read -r -d '' script; do
    test -x "$script" || fail "managed script is not executable: $script"
    bash -n "$script"
done < <(find "$repo_root/desktop/waybar/scripts" -type f -name '*.sh' -print0)

test -f "$waybar_config" || fail 'deployed Waybar modules are missing'
! rg -Fq '@HOME@' "$waybar_config" || fail 'deployed Waybar modules contain an unresolved home path'
test -s "$plugin_path" || fail "missing Niri Taskbar library: $plugin_path"

printf 'PASS: portable desktop deployment is valid\n'
