#!/usr/bin/env bash

set -euo pipefail

APP_ID='com.super_productivity.SuperProductivity'

window_id=$(niri msg -j windows | jq -r --arg app_id "$APP_ID" '
    [.[] | select(.app_id == $app_id) | .id] | first // empty
')

if [[ -n $window_id ]]; then
    exec niri msg action focus-window --id "$window_id"
fi

exec super-productivity
