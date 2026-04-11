#!/bin/bash

# Identify OS and Variant
OS="$(grep '^ID=' /etc/os-release | cut -d= -f2)"
VARIANT="$(grep '^VARIANT_ID=' /etc/os-release | cut -d= -f2)"
if [ -n "$VARIANT" ]; then
  OS="${OS}-${VARIANT}"
fi
echo $OS
# Build log file for upgradeable package counts/errors
COUNT_FILE="$HOME/.local/state/upgradeable"
echo Default $COUNT_FILE
if [ -f "/run/.containerenv" ] || [ -f "/.dockerenv" ]; then
  COUNT_FILE="$COUNT_FILE.$(echo "$HOSTNAME" | cut -d'.' -f1)"
  echo Container $COUNT_FILE
fi

# Build command
CMD=${0//pkg/pkg-$OS}
echo $CMD

# Log error if command does not exist and exit
if [ ! -f "$CMD" ]; then
  echo "ERROR: unsupported OS/variant '$OS' due to missing script: $CMD" > "$COUNT_FILE"
  exit
fi

# Run appropriate script from same path as this one
$CMD "$@"
