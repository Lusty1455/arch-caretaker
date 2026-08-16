#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
data_home=${XDG_DATA_HOME:-"$HOME/.local/share"}
backup_root=${ARCH_CARETAKER_BACKUP_DIR:-"$repo_root/backup"}
timestamp=$(date -u +%Y%m%dT%H%M%SZ)

backup_target() {
    local name=$1
    local target=$2

    if [[ -e "$target" || -L "$target" ]]; then
        install -d "$backup_root"
        mv "$target" "$backup_root/$name-$timestamp"
    fi
}

deploy_waybar() {
    local target="$config_home/waybar"
    backup_target waybar "$target"
    install -d "$target"
    rsync -a --delete "$repo_root/desktop/waybar/" "$target/"

    local escaped_home
    escaped_home=$(printf '%s' "$HOME" | sed 's/[&|\\]/\\&/g')
    sed -i "s|@HOME@|$escaped_home|g" "$target/modules.jsonc"
}

deploy_niri() {
    local target="$config_home/niri"
    backup_target niri "$target"
    install -d "$target/scripts"
    install -m 644 "$repo_root/desktop/niri/config.kdl" "$target/config.kdl"
    install -m 755 "$repo_root/desktop/niri/swayidle.sh" "$target/scripts/swayidle.sh"
}

deploy_application() {
    install -Dm644 "$repo_root/desktop/applications/swaylock.desktop" \
        "$data_home/applications/swaylock.desktop"
}

deploy_waybar
deploy_niri
deploy_application

printf 'Deployed Waybar and Niri configuration.\n'
