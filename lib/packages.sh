#!/usr/bin/env bash

# Load packages dynamically from JSON config
CONFIG_FILE="$SCRIPT_DIR/config/packages.json"

parse_json_array() {
    local key="$1"
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import json, sys; data=json.load(sys.stdin); print('\n'.join(data.get('$key', [])))" < "$CONFIG_FILE"
    else
        echo -e "\033[0;31m[ERROR]\033[0m Python 3 is required to parse the JSON configuration." >&2
        exit 1
    fi
}

required_packages=()
while IFS= read -r line; do
  [[ -n "$line" ]] && required_packages+=("$line")
done < <(parse_json_array "required_packages")

formulae_packages=()
while IFS= read -r line; do
  [[ -n "$line" ]] && formulae_packages+=("$line")
done < <(parse_json_array "formulae_packages")

cask_packages=()
while IFS= read -r line; do
  [[ -n "$line" ]] && cask_packages+=("$line")
done < <(parse_json_array "cask_packages")
