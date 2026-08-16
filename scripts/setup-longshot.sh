#!/usr/bin/env bash
set -Eeuo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
venv_dir="$repo_root/desktop/waybar/scripts/longshot-sh/venv"

python3 -m venv "$venv_dir"
"$venv_dir/bin/pip" install -r "$repo_root/packages/python-longshot.txt"

printf 'Prepared longshot Python environment.\n'
