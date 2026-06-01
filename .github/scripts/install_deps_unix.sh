#!/bin/bash
# Install system dependencies for Unix builds
# Usage: ./install_deps_unix.sh [gcc|clang]

set -euo pipefail

COMPILER="${1:-gcc}"

echo "[DEPS] Installing system dependencies for $COMPILER"

sudo apt-get update -q

if [[ "$COMPILER" == "clang" ]]; then
  sudo apt-get install -y --no-install-recommends \
    ninja-build clang cmake curl zip unzip tar pkg-config
else
  sudo apt-get install -y --no-install-recommends \
    ninja-build gcc g++ cmake curl zip unzip tar pkg-config
fi

echo "[DEPS] Dependencies installed successfully"
