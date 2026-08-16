#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

usage() {
    cat <<'EOF'
Usage: scripts/install.sh [--all|--packages|--aur|--longshot|--build-plugin|--deploy|--verify|--help]

--all           Install packages, rebuild local components, deploy, and verify.
--packages      Install official Arch packages through a Polkit prompt.
--aur           Install AUR packages through paru.
--longshot      Recreate the long-screenshot Python environment.
--build-plugin  Build the Niri Taskbar Waybar plugin.
--deploy        Copy the canonical Waybar and Niri configuration into XDG paths.
--verify        Validate the current deployment.
EOF
}

read_manifest() {
    local manifest=$1
    mapfile -t packages < <(rg -v '^#' "$manifest")
}

install_packages() {
    local -a packages
    read_manifest "$repo_root/packages/pacman.txt"
    pkexec pacman -S --needed "${packages[@]}"
}

install_aur() {
    local -a packages
    command -v paru >/dev/null 2>&1 || {
        printf 'Install paru first, then rerun scripts/install.sh --aur\n' >&2
        return 1
    }
    read_manifest "$repo_root/packages/aur.txt"
    paru -S --needed "${packages[@]}"
}

run_all() {
    install_packages
    install_aur
    "$repo_root/scripts/setup-longshot.sh"
    "$repo_root/scripts/build-niri-taskbar.sh"
    "$repo_root/scripts/deploy.sh"
    "$repo_root/scripts/verify.sh"
}

case ${1:---all} in
    --all) run_all ;;
    --packages) install_packages ;;
    --aur) install_aur ;;
    --longshot) "$repo_root/scripts/setup-longshot.sh" ;;
    --build-plugin) "$repo_root/scripts/build-niri-taskbar.sh" ;;
    --deploy) "$repo_root/scripts/deploy.sh" ;;
    --verify) "$repo_root/scripts/verify.sh" ;;
    --help|-h) usage ;;
    *) usage >&2; exit 2 ;;
esac
