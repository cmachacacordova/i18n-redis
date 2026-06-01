#!/bin/bash
# Create binary package for Unix
# Usage: ./create_binary_package.sh <variant> [install_dir]

set -euo pipefail

VARIANT="${1:-}"
INSTALL_DIR="${2:-out/install}"

if [[ -z "$VARIANT" ]]; then
  echo "[PACKAGE] ERROR: No variant specified"
  echo "Usage: $0 <variant> [install_dir]"
  exit 1
fi

# Get version
VERSION_FILE=".version"
if [[ -f "$VERSION_FILE" ]]; then
  VERSION="$(cat "$VERSION_FILE" | tr -d '[:space:]')"
else
  VERSION="unknown"
fi

INSTALL_PATH="$INSTALL_DIR/$VARIANT"
OUTPUT_DIR="release"
PKG_NAME="i18n-redis-${VERSION}-${VARIANT}.tar.gz"

echo "[PACKAGE] Creating binary package: $PKG_NAME"
echo "[PACKAGE] From install directory: $INSTALL_PATH"

if [[ ! -d "$INSTALL_PATH" ]]; then
  echo "[PACKAGE] ERROR: Install directory not found: $INSTALL_PATH"
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Create temp directory for staging
TEMP_DIR=$(mktemp -d)

# Copy install tree
cp -r "$INSTALL_PATH/"* "$TEMP_DIR/"

# Copy LICENSE and package README
cp "LICENSE" "$TEMP_DIR/"
cp ".github/templates/README_PACKAGE.md" "$TEMP_DIR/README.md"

# Create tar.gz
tar -czf "$OUTPUT_DIR/$PKG_NAME" -C "$TEMP_DIR" .

# Cleanup
rm -rf "$TEMP_DIR"

echo "[PACKAGE] Created: $OUTPUT_DIR/$PKG_NAME"
ls -lh "$OUTPUT_DIR/$PKG_NAME"
