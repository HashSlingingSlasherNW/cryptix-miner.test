#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

. "$SCRIPT_DIR/h-manifest.conf"

NAME="$CUSTOM_NAME"
VERSION="$CUSTOM_VERSION"
MINERBIN="$CUSTOM_MINERBIN"
PACKAGE_DIR="$NAME"
ARCHIVE_NAME="$NAME.tar.gz"

if [[ ! -f "$MINERBIN" ]]; then
    echo "Missing miner binary: $SCRIPT_DIR/$MINERBIN"
    exit 1
fi

rm -rf "$PACKAGE_DIR" "$ARCHIVE_NAME"
mkdir -p "$PACKAGE_DIR"
cp h-manifest.conf h-config.sh h-run.sh h-stats.sh "$MINERBIN" "$PACKAGE_DIR/"
tar -czf "$ARCHIVE_NAME" "$PACKAGE_DIR"

echo "Created $ARCHIVE_NAME for $NAME ($VERSION)"
