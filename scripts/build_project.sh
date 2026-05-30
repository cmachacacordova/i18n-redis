#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <static|shared> <debug|release> [gcc|clang] [simdjson|yyjson]" >&2
  echo "" >&2
  echo "  If VCPKG_HOME is unset, the bundled submodule (extras/vcpkg) is used automatically." >&2
  exit 1
}

[ $# -ge 2 ] || usage

TYPE=$1
MODE=$2
COMPILER=${3:-gcc}
JSON_BACKEND=${4:-simdjson}

case "$TYPE" in
  static|shared) ;;
  *) usage;;
esac

case "$MODE" in
  debug|release) ;;
  *) usage;;
esac

case "$COMPILER" in
  gcc|clang) ;;
  *) usage;;
esac

case "$JSON_BACKEND" in
  simdjson|yyjson) ;;
  *) usage;;
esac

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

if [ -z "${VCPKG_HOME:-}" ]; then
  SUBMODULE_VCPKG="$ROOT_DIR/extras/vcpkg"
  echo "VCPKG_HOME is not set — using bundled submodule at extras/vcpkg"
  git -C "$ROOT_DIR" submodule update --init --recursive extras/vcpkg
  if [ ! -f "$SUBMODULE_VCPKG/vcpkg" ] && [ ! -f "$SUBMODULE_VCPKG/vcpkg.exe" ]; then
    echo "Bootstrapping vcpkg..."
    "$SUBMODULE_VCPKG/bootstrap-vcpkg.sh" -disableMetrics
  fi
  VCPKG_HOME="$SUBMODULE_VCPKG"
  echo "  VCPKG_HOME set to: $VCPKG_HOME"
  echo ""
fi

echo "Build configuration:"
echo "  Type:         $TYPE"
echo "  Mode:         $MODE"
echo "  Compiler:     $COMPILER"
echo "  JSON backend: $JSON_BACKEND"
echo "  VCPKG_HOME:   $VCPKG_HOME"
echo ""

if [ "$JSON_BACKEND" = "yyjson" ]; then
  PRESET="linux-${COMPILER}-${TYPE}-${MODE}-yyjson"
else
  PRESET="linux-${COMPILER}-${TYPE}-${MODE}"
fi

cmake --preset "$PRESET" --fresh -S "$ROOT_DIR"
cmake --build --preset "$PRESET" --parallel
