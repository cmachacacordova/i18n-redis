#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
VCPKG_DIR="$ROOT_DIR/external/vcpkg"

if [ -d "$VCPKG_DIR" ]; then
  echo "vcpkg already installed at $VCPKG_DIR"
  exit 0
fi

mkdir -p "$ROOT_DIR/external"
echo "Cloning vcpkg to $VCPKG_DIR..."
git clone https://github.com/microsoft/vcpkg.git "$VCPKG_DIR"

if [[ "${MSYSTEM:-}" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
  cmd.exe /c "$VCPKG_DIR\\bootstrap-vcpkg.bat" -disableMetrics
else
  "$VCPKG_DIR/bootstrap-vcpkg.sh" -disableMetrics
fi

echo "vcpkg installed at $VCPKG_DIR"
