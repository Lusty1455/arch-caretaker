#!/usr/bin/env bash

set -euo pipefail

SCRIPT="$HOME/.config/waybar/scripts/super-productivity-status.sh"
TOGGLE_SCRIPT="$HOME/.config/waybar/scripts/super-productivity-display-mode.sh"
MOCK_BIN='/tmp/waybar-sp-test-bin'
MODE_FILE='/tmp/waybar-sp-test-display-mode'

cleanup() {
    rm -f "$MODE_FILE"
}

trap cleanup EXIT

assert_mode_toggle() {
    local actual

    if ! SUPER_PRODUCTIVITY_DISPLAY_MODE_FILE="$MODE_FILE" "$TOGGLE_SCRIPT" toggle; then
        printf 'FAIL: toggles the display mode\n' >&2
        return 1
    fi

    actual=$(<"$MODE_FILE")
    if [[ $actual != compact ]]; then
        printf 'FAIL: toggles the display mode\n  expected: compact\n  actual:   %s\n' "$actual" >&2
        return 1
    fi

    SUPER_PRODUCTIVITY_DISPLAY_MODE_FILE="$MODE_FILE" "$TOGGLE_SCRIPT" toggle
    actual=$(<"$MODE_FILE")
    if [[ $actual != detailed ]]; then
        printf 'FAIL: toggles the display mode\n  expected: detailed\n  actual:   %s\n' "$actual" >&2
        return 1
    fi

    printf 'PASS: toggles the display mode\n'
}

assert_text() {
    local name=$1
    local response=$2
    local expected=$3
    local curl_fail=${4:-0}
    local tasks_response=${5:-}
    local display_mode=${6:-detailed}
    local output actual

    rm -f "$MODE_FILE"
    if [[ $display_mode == compact ]]; then
        printf '%s\n' compact >"$MODE_FILE"
    fi

    output=$(PATH="$MOCK_BIN:$PATH" MOCK_CURL_RESPONSE="$response" MOCK_CURL_CURRENT_RESPONSE="$response" MOCK_CURL_TASKS_RESPONSE="$tasks_response" MOCK_CURL_FAIL="$curl_fail" SUPER_PRODUCTIVITY_DISPLAY_MODE_FILE="$MODE_FILE" "$SCRIPT")
    actual=$(jq -r '.text' <<<"$output")

    if [[ $actual != "$expected" ]]; then
        printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$name" "$expected" "$actual" >&2
        return 1
    fi

    printf 'PASS: %s\n' "$name"
}

assert_mode_toggle

assert_text \
    'shows spent and estimated minutes for the active task' \
    '{"ok":true,"data":{"title":"112","timeSpent":480000,"timeEstimate":1800000}}' \
    '󰄬 112 · 8m/30m'

assert_text \
    'shows hours and remaining minutes for long durations' \
    '{"ok":true,"data":{"title":"112","timeSpent":3900000,"timeEstimate":5400000}}' \
    '󰄬 112 · 1h5m/1h30m'

assert_text \
    'omits zero minutes from an exact hour' \
    '{"ok":true,"data":{"title":"112","timeSpent":3600000,"timeEstimate":7200000}}' \
    '󰄬 112 · 1h/2h'

assert_text \
    'keeps the task-only display when no estimate is set' \
    '{"ok":true,"data":{"title":"112","timeSpent":480000,"timeEstimate":0}}' \
    '󰄬 112'

assert_text \
    'keeps the idle display when there is no current task' \
    '{"ok":true,"data":null}' \
    '󰄬'

assert_text \
    'keeps the offline display when the API request fails' \
    '' \
    '󰄬' \
    1

assert_text \
    'shows child-only aggregate totals and current subtask time estimates' \
    '{"ok":true,"data":{"id":"child-1","title":"吃饭1","parentId":"parent-1","timeSpent":600000,"timeEstimate":1800000}}' \
    '󰄬 吃饭-15m/1h——吃饭1(1/3)-10m/30m' \
    0 \
    '{"ok":true,"data":[{"id":"parent-1","title":"吃饭","timeSpent":120000,"timeEstimate":7200000,"parentId":null,"isDone":false},{"id":"child-1","title":"吃饭1","timeSpent":600000,"timeEstimate":1800000,"parentId":"parent-1","isDone":false},{"id":"child-2","title":"吃饭2","timeSpent":300000,"timeEstimate":600000,"parentId":"parent-1","isDone":true},{"id":"child-3","title":"吃饭3","timeSpent":0,"timeEstimate":1200000,"parentId":"parent-1","isDone":false}]}'

assert_text \
    'shows parent child progress and total spent time in compact mode' \
    '{"ok":true,"data":{"id":"child-1","title":"吃饭1","parentId":"parent-1","timeSpent":600000,"timeEstimate":1800000}}' \
    '吃饭-吃饭1(1/3) 15m' \
    0 \
    '{"ok":true,"data":[{"id":"parent-1","title":"吃饭","timeSpent":120000,"timeEstimate":7200000,"parentId":null,"isDone":false},{"id":"child-1","title":"吃饭1","timeSpent":600000,"timeEstimate":1800000,"parentId":"parent-1","isDone":false},{"id":"child-2","title":"吃饭2","timeSpent":300000,"timeEstimate":600000,"parentId":"parent-1","isDone":true},{"id":"child-3","title":"吃饭3","timeSpent":0,"timeEstimate":1200000,"parentId":"parent-1","isDone":false}]}' \
    compact
