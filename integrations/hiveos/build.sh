#!/usr/bin/env bash

NAME="cryptix_miner_hive_sheet_v029"
VERSION="v0.2.9"
MINERBIN="cryptix-miner"

# Create the manifest file
cat > h-manifest.conf << EOF
# cryptix-miner manifest for HiveOS

CUSTOM_NAME=$NAME
CUSTOM_VERSION=$VERSION
CUSTOM_BUILD=0
CUSTOM_MINERBIN=$MINERBIN
CUSTOM_CONFIG_FILENAME=/hive/miners/custom/\$CUSTOM_NAME/config.ini
CUSTOM_LOG_BASENAME=/var/log/miner/\$CUSTOM_NAME
WEB_PORT=3338
EOF

# Prepare the package directory
mkdir -p $NAME

# Copy all required files into the package directory
cp h-manifest.conf *.sh $MINERBIN $NAME/

# Create the archive
tar czf $NAME.tar.gz $NAME
