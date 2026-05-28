#!/usr/bin/env bash
set -e

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

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

"$SCRIPT_DIR/install_vcpkg.sh"

VCPKG="$ROOT_DIR/external/vcpkg/vcpkg"
OVERLAY="$ROOT_DIR/ports-overlay"

if [ "$TYPE" = "static" ]; then
    TRIPLET="x64-linux"
else
    TRIPLET="x64-linux-dynamic"
fi

"$VCPKG" install --triplet "$TRIPLET" --overlay-ports="$OVERLAY"

PRESET="linux-${COMPILER}-${TYPE}-${MODE}"

cmake --preset "$PRESET"
cmake --build --preset "$PRESET" --clean-first --parallel
