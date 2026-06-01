#!/bin/bash
# Organize release files from artifacts
# Usage: ./organize_release_files.sh <artifacts_dir> <release_dir>

set -euo pipefail

ARTIFACTS_DIR="${1:-artifacts}"
RELEASE_DIR="${2:-release}"

if [[ ! -d "$ARTIFACTS_DIR" ]]; then
  echo "[ORGANIZE] ERROR: Artifacts directory not found: $ARTIFACTS_DIR"
  exit 1
fi

mkdir -p "$RELEASE_DIR"

echo "[ORGANIZE] Organizing release files from: $ARTIFACTS_DIR"

# Move source package
if [[ -d "$ARTIFACTS_DIR/i18n-redis-source" ]]; then
  cp "$ARTIFACTS_DIR"/i18n-redis-source/*.tar.gz "$RELEASE_DIR/" 2>/dev/null || true
fi

# Move Unix binary packages
for dir in "$ARTIFACTS_DIR"/linux-*/; do
  if [[ -d "$dir" ]]; then
    cp "$dir"/*.tar.gz "$RELEASE_DIR/" 2>/dev/null || true
  fi
done

# Move Windows binary packages
for dir in "$ARTIFACTS_DIR"/windows-msvc-*/; do
  if [[ -d "$dir" ]]; then
    cp "$dir"/*.zip "$RELEASE_DIR/" 2>/dev/null || true
  fi
done

echo "[ORGANIZE] Release files:"
ls -la "$RELEASE_DIR/"
