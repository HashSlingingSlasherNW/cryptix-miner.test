#!/usr/bin/env bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_PATH="$SCRIPT_DIR/h-manifest.conf"

if [[ ! -f "$MANIFEST_PATH" ]]; then
    echo "Missing manifest file: $MANIFEST_PATH"
    exit 1
fi

. "$MANIFEST_PATH"

conf=""
[[ -n "${CUSTOM_URL:-}" ]] && conf+=" --cryptixd-address=$CUSTOM_URL"
[[ -n "${CUSTOM_TEMPLATE:-}" ]] && conf+=" --mining-address $CUSTOM_TEMPLATE"
[[ -n "${CUSTOM_USER_CONFIG:-}" ]] && conf+=" $CUSTOM_USER_CONFIG"

mkdir -p "$(dirname "$CUSTOM_CONFIG_FILENAME")"
echo "$conf"
echo "$conf" > "$CUSTOM_CONFIG_FILENAME"
