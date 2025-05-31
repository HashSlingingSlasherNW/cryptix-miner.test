#!/usr/bin/env bash

VERSION="v0.2.9"
BINARY="cryptix-miner"
TARGET_DIR="cryptix_miner_hive_sheet_v029"

./createmanifest.sh "$VERSION" "$BINARY"
mkdir -p "$TARGET_DIR"
cp h-manifest.conf *.sh "$BINARY" "$TARGET_DIR/"
tar cvf "${TARGET_DIR}.tar.gz" "$TARGET_DIR"