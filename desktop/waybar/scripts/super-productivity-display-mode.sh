#!/usr/bin/env bash

set -euo pipefail

MODE_FILE=${SUPER_PRODUCTIVITY_DISPLAY_MODE_FILE:-"${XDG_CACHE_HOME:-$HOME/.cache}/waybar/super-productivity-display-mode"}

case ${1:-toggle} in
    toggle)
        current_mode=detailed
        [[ -r $MODE_FILE ]] && read -r current_mode <"$MODE_FILE"

        if [[ $current_mode == compact ]]; then
            next_mode=detailed
        else
            next_mode=compact
        fi

        mkdir -p "$(dirname "$MODE_FILE")"
        printf '%s\n' "$next_mode" >"$MODE_FILE"
        ;;
    *)
        printf 'Usage: %s [toggle]\n' "$0" >&2
        exit 2
        ;;
esac
