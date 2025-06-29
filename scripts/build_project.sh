#!/usr/bin/env bash
set -e

usage() {
    echo "Uso: $0 <static|shared|both> <release|debug>" >&2
    exit 1
}

[ $# -eq 2 ] || usage

TYPE=$1
MODE=$2

case "$TYPE" in
    static|shared|both) ;;
    *) usage;;
esac

case "$MODE" in
    release|debug) ;;
    *) usage;;
esac

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

"$SCRIPT_DIR/install_vcpkg.sh"

VCPKG="$ROOT_DIR/external/vcpkg/vcpkg"

if [ "$TYPE" = "static" ]; then
    "$VCPKG" install --triplet x64-linux-static
    PRESET="linux-static-$MODE"
elif [ "$TYPE" = "shared" ]; then
    "$VCPKG" install --triplet x64-linux
    PRESET="linux-shared-$MODE"
else
    "$VCPKG" install --triplet x64-linux-static
    PRESET="linux-both-$MODE"
fi

cmake --preset "$PRESET"
cmake --build "out/$PRESET"
