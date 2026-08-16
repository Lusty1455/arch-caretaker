#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd "$(dirname "$0")" && pwd)
config_home=${XDG_CONFIG_HOME:-"$HOME/.config"}
data_home=${XDG_DATA_HOME:-"$HOME/.local/share"}
target_dir="$config_home/niri/scripts"
target="$target_dir/swayidle.sh"
desktop_target_dir="$data_home/applications"
desktop_target="$desktop_target_dir/swaylock.desktop"

mkdir -p "$target_dir"
ln -sfn "$script_dir/swayidle.sh" "$target"
mkdir -p "$desktop_target_dir"
ln -sfn "$script_dir/../applications/swaylock.desktop" "$desktop_target"
printf 'Linked %s -> %s\n' "$target" "$script_dir/swayidle.sh"
printf 'Linked %s -> %s\n' "$desktop_target" "$script_dir/../applications/swaylock.desktop"
