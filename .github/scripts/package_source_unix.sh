#!/bin/bash
# Package source distribution for Unix (tar.gz)
# Creates a clean source package without binaries, build artifacts, or extras/
# Usage: package_source_unix.sh [output_dir]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$GITHUB_DIR")"
OUTPUT_DIR="${1:-$PROJECT_ROOT/release}"
VERSION_FILE="$PROJECT_ROOT/.version"

if [[ ! -f "$VERSION_FILE" ]]; then
  echo "[ERROR] Version file not found: $VERSION_FILE"
  exit 1
fi

VERSION="$(cat "$VERSION_FILE" | tr -d '[:space:]')"
PKG_NAME="i18n-redis-${VERSION}-unix.tar.gz"
PKG_PATH="$OUTPUT_DIR/$PKG_NAME"

echo "[PACKAGER] Creating Unix source package"
echo "[PACKAGER] Version: $VERSION"
echo "[PACKAGER] Output: $PKG_PATH"

mkdir -p "$OUTPUT_DIR"

TEMP_STAGING=$(mktemp -d)
STAGING_DIR="$TEMP_STAGING/i18n-redis-${VERSION}"
mkdir -p "$STAGING_DIR"

# Copy essential build files
cp "$PROJECT_ROOT/CMakeLists.txt" "$STAGING_DIR/"
cp "$PROJECT_ROOT/CMakePresets.json" "$STAGING_DIR/"
cp "$PROJECT_ROOT/vcpkg.json" "$STAGING_DIR/"
cp "$PROJECT_ROOT/vcpkg-configuration.json" "$STAGING_DIR/"
cp "$PROJECT_ROOT/configure" "$STAGING_DIR/"
cp "$PROJECT_ROOT/LICENSE" "$STAGING_DIR/"
cp "$PROJECT_ROOT/README.md" "$STAGING_DIR/"
cp "$PROJECT_ROOT/.version" "$STAGING_DIR/"

# Copy directories needed for building
cp -r "$PROJECT_ROOT/include" "$STAGING_DIR/"
cp -r "$PROJECT_ROOT/src" "$STAGING_DIR/"
cp -r "$PROJECT_ROOT/cmake" "$STAGING_DIR/"
cp -r "$PROJECT_ROOT/locales" "$STAGING_DIR/"
cp -r "$PROJECT_ROOT/example" "$STAGING_DIR/"
cp -r "$PROJECT_ROOT/tests" "$STAGING_DIR/"

# Create tar.gz excluding unwanted files
tar -czf "$PKG_PATH" -C "$TEMP_STAGING" \
  --exclude='*.o' --exclude='*.a' --exclude='*.so' --exclude='*.so.*' \
  --exclude='*.dll' --exclude='*.exe' --exclude='*.lib' --exclude='*.pdb' \
  --exclude='*.ilk' --exclude='out/*' --exclude='build/*' --exclude='.git/*' \
  --exclude='.github/*' --exclude='.vscode/*' --exclude='.windsurf/*' \
  --exclude='extras/*' --exclude='vcpkg_installed/*' \
  "i18n-redis-${VERSION}"

rm -rf "$TEMP_STAGING"

echo "[PACKAGER] Package created: $PKG_PATH"
ls -lh "$PKG_PATH"

# Verify package contents
echo "[PACKAGER] Verifying package contents..."
if tar -tzf "$PKG_PATH" | grep -qE '\.(o|a|so|dll|exe|lib|pdb)$'; then
  echo "[ERROR] Package contains binary files!"
  exit 1
fi
if tar -tzf "$PKG_PATH" | grep -qE '^[^/]+/extras/'; then
  echo "[ERROR] Package contains extras/ directory!"
  exit 1
fi
echo "[PACKAGER] Verification passed: no binaries or extras found"
