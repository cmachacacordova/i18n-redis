#!/bin/bash
# Bootstrap vcpkg on Unix systems
# Usage: ./.github/scripts/bootstrap_vcpkg_unix.sh [vcpkg_path]

set -euo pipefail

VCPKG_DIR="${1:-extras/vcpkg}"
VCPKG_EXE="$VCPKG_DIR/vcpkg"

if [ -f "$VCPKG_EXE" ]; then
  echo "vcpkg is already bootstrapped at $VCPKG_DIR"
  exit 0
fi

if [ ! -f "$VCPKG_DIR/bootstrap-vcpkg.sh" ]; then
  echo "ERROR: vcpkg bootstrap script not found at $VCPKG_DIR/bootstrap-vcpkg.sh"
  exit 1
fi

echo "Bootstrapping vcpkg..."
"$VCPKG_DIR/bootstrap-vcpkg.sh" -disableMetrics
