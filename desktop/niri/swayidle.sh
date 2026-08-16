#!/usr/bin/env bash
set -euo pipefail

exec swayidle -w \
  timeout 300 'swaylock -f' \
  timeout 600 'niri msg action power-off-monitors' \
  resume 'niri msg action power-on-monitors' \
  before-sleep 'swaylock -f'
