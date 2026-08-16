#!/usr/bin/env bash

set -euo pipefail

SCRIPT="$HOME/.config/waybar/scripts/focus-super-productivity.sh"
TEST_DIR=$(mktemp -d /tmp/waybar-focus-super-productivity.XXXXXX)
MOCK_BIN="$TEST_DIR/bin"
CALL_LOG="$TEST_DIR/calls"

cleanup() {
    rm -rf -- "$TEST_DIR"
}

trap cleanup EXIT
mkdir -p "$MOCK_BIN"

cat >"$MOCK_BIN/niri" <<'EOF'
#!/usr/bin/env bash
if [[ $1 == msg && $2 == -j && $3 == windows ]]; then
    printf '%s\n' "$MOCK_WINDOWS"
else
    printf 'niri %s\n' "$*" >>"$CALL_LOG"
fi
EOF

cat >"$MOCK_BIN/super-productivity" <<'EOF'
#!/usr/bin/env bash
printf 'super-productivity\n' >>"$CALL_LOG"
EOF

chmod +x "$MOCK_BIN/niri" "$MOCK_BIN/super-productivity"

assert_call() {
    local name=$1
    local windows=$2
    local expected=$3
    local actual

    : >"$CALL_LOG"
    PATH="$MOCK_BIN:$PATH" MOCK_WINDOWS="$windows" CALL_LOG="$CALL_LOG" "$SCRIPT"
    actual=$(<"$CALL_LOG")

    if [[ $actual != "$expected" ]]; then
        printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$name" "$expected" "$actual" >&2
        return 1
    fi

    printf 'PASS: %s\n' "$name"
}

assert_call \
    'focuses the existing Super Productivity window' \
    '[{"id":42,"app_id":"com.super_productivity.SuperProductivity"}]' \
    'niri msg action focus-window --id 42'

assert_call \
    'starts Super Productivity when no matching window exists' \
    '[]' \
    'super-productivity'
