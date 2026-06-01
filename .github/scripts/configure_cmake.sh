#!/bin/bash
# Configure CMake with vcpkg toolchain
# Usage: ./configure_cmake.sh <preset> [extra_cmake_args...]

set -euo pipefail

PRESET="${1:-}"
shift || true

if [[ -z "$PRESET" ]]; then
  echo "[CONFIGURE] ERROR: No preset specified"
  echo "Usage: $0 <preset> [extra_cmake_args...]"
  exit 1
fi

# Determine JSON backend from preset name
if [[ "$PRESET" == *-yyjson* ]]; then
  FEATURE="yyjson"
else
  FEATURE="simdjson"
fi

echo "[CONFIGURE] Configuring preset: $PRESET"
echo "[CONFIGURE] vcpkg feature: $FEATURE"

# Set defaults for vcpkg environment variables
VCPKG_HOME="${VCPKG_HOME:-${GITHUB_WORKSPACE:-$(pwd)}/extras/vcpkg}"
VCPKG_OVERLAY_TRIPLETS="${VCPKG_OVERLAY_TRIPLETS:-${GITHUB_WORKSPACE:-$(pwd)}/extras/registry/triplets}"
VCPKG_OVERLAY_PORTS="${VCPKG_OVERLAY_PORTS:-${GITHUB_WORKSPACE:-$(pwd)}/extras/registry/ports}"

cmake --preset "$PRESET" \
  -DCMAKE_TOOLCHAIN_FILE="$VCPKG_HOME/scripts/buildsystems/vcpkg.cmake" \
  -DVCPKG_MANIFEST_FEATURES="$FEATURE" \
  -DVCPKG_OVERLAY_TRIPLETS="$VCPKG_OVERLAY_TRIPLETS" \
  -DVCPKG_OVERLAY_PORTS="$VCPKG_OVERLAY_PORTS" \
  "$@"

echo "[CONFIGURE] Configuration complete"
