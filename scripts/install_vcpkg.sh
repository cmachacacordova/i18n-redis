#!/usr/bin/env bash
set -e
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
VCPKG_DIR="$ROOT_DIR/external/vcpkg"

if [ -d "$VCPKG_DIR" ]; then
    echo "vcpkg ya esta instalado en $VCPKG_DIR"
    exit 0
fi

mkdir -p "$ROOT_DIR/external"
echo "Clonando vcpkg en $VCPKG_DIR..."
git clone https://github.com/microsoft/vcpkg.git "$VCPKG_DIR"

if [ "$(uname -o 2>/dev/null)" = "Msys" ] || [[ "$(uname -s)" == *"NT"* ]]; then
    cmd.exe /c "$VCPKG_DIR\\bootstrap-vcpkg.bat" -disableMetrics
else
    "$VCPKG_DIR/bootstrap-vcpkg.sh" -disableMetrics
fi

echo "vcpkg instalado en $VCPKG_DIR"
