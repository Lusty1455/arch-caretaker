#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
destination=${NIRI_TASKBAR_DEST:-"$HOME/.local/lib/waybar/libniri_taskbar_current_workspace.so"}

cd "$repo_root/desktop/niri-taskbar"
cargo build --release
install -Dm755 target/release/libniri_taskbar.so "$destination"
