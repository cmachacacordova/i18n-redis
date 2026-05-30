#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <static|shared> <debug|release> [gcc|clang]" >&2
  exit 1
}

[ $# -ge 2 ] || usage

TYPE=$1
MODE=$2
COMPILER=${3:-gcc}

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

if [[ -z "${VCPKG_HOME:-}" ]] || [[ ! -x "$VCPKG_HOME/vcpkg" ]]; then
  echo "Error: VCPKG_HOME is not set or does not point to a valid vcpkg installation." >&2
  echo "       export VCPKG_HOME=/path/to/vcpkg" >&2
  exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

echo "Using vcpkg: $VCPKG_HOME/vcpkg"

echo "Updating git submodules..."
git -C "$ROOT_DIR" submodule update --init --remote --merge 2>/dev/null || true

PRESET="linux-${COMPILER}-${TYPE}-${MODE}"

cmake --preset "$PRESET" --fresh
cmake --build out/build --parallel
