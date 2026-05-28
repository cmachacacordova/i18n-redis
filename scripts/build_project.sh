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

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
VCPKG_DIR="$ROOT_DIR/external/vcpkg"

detectVcpkg() {
  if [ -d "$VCPKG_DIR" ] && [ -x "$VCPKG_DIR/vcpkg" ]; then
    echo "$VCPKG_DIR/vcpkg"
    return 0
  fi
  if [[ "${VCPKG_HOME:-}" ]] && [ -d "$VCPKG_HOME" ] && [ -x "$VCPKG_HOME/vcpkg" ]; then
    echo "$VCPKG_HOME/vcpkg"
    return 0
  fi
  return 1
}

VCPKG=$(detectVcpkg) || {
  echo "vcpkg not found. Installing to $VCPKG_DIR..."
  "$SCRIPT_DIR/install_vcpkg.sh"
  VCPKG=$(detectVcpkg) || {
    echo "Error: vcpkg installation failed" >&2
    exit 1
  }
}

echo "Using vcpkg: $VCPKG"

export VCPKG_HOME=$(dirname "$VCPKG")

PRESET="linux-${COMPILER}-${TYPE}-${MODE}"

rm -rf out/build
cmake --preset "$PRESET"
cmake --build out/build --parallel
