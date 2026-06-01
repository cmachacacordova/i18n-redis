#!/bin/bash
# Script to package release artifacts for i18n-redis
# This script is used by GitHub Actions - not intended for direct user use.
# Usage: ./.github/scripts/package_release.sh [source|binary] [output_dir]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITHUB_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$GITHUB_DIR")"
PACKAGE_TYPE="${1:-source}"
OUTPUT_DIR="${2:-$PROJECT_ROOT/release}"
VERSION_FILE="$PROJECT_ROOT/.version"

# Read version
if [[ -f "$VERSION_FILE" ]]; then
  VERSION="$(cat "$VERSION_FILE" | tr -d '[:space:]')"
else
  VERSION="unknown"
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

echo "[PACKAGER] Packaging type: $PACKAGE_TYPE"
echo "[PACKAGER] Output directory: $OUTPUT_DIR"
echo "[PACKAGER] Version: $VERSION"

# Function to validate package contents
validate_source_package() {
  local pkg_file="$1"
  local errors=0

  echo "[PACKAGER] Validating source package: $(basename "$pkg_file")"

  tar_contains() {
    local pattern="$1"
    tar -tzf "$pkg_file" | grep -E "$pattern" >/dev/null
  }

  # Files/directories that should NOT be in source package
  local excluded_patterns=(
    '^[^/]+/\.git/'
    '^[^/]+/\.github/'
    '^[^/]+/\.vscode/'
    '^[^/]+/\.windsurf/'
    '^[^/]+/\.actrc'
    '^[^/]+/\.clang-format'
    '^[^/]+/\.clangd'
    '^[^/]+/\.gitignore'
    '^[^/]+/\.gitmodules'
    '^[^/]+/\.gitattributes'
    '^[^/]+/out/'
    '^[^/]+/vcpkg_installed/'
    '^[^/]+/extras/registry/'
    '\.o$'
    '\.a$'
    '\.so$'
    '\.so\.[0-9]'
    '\.dll$'
    '\.exe$'
    '\.lib$'
    '\.pdb$'
    '\.ilk$'
  )

  # Check for excluded files
  for pattern in "${excluded_patterns[@]}"; do
    local matches
    matches=$(tar -tzf "$pkg_file" | grep -E "$pattern" || true)
    if [[ -n "$matches" ]]; then
      echo "[PACKAGER] ERROR: Found excluded pattern '$pattern':"
      echo "$matches" | head -5
      errors=$((errors + 1))
    fi
  done

  # Files that MUST be in source package
  local required_patterns=(
    '^[^/]+/CMakeLists\.txt$'
    '^[^/]+/CMakePresets\.json$'
    '^[^/]+/vcpkg\.json$'
    '^[^/]+/vcpkg-configuration\.json$'
    '^[^/]+/configure$'
    '^[^/]+/LICENSE$'
    '^[^/]+/README\.md$'
    '^[^/]+/\.version$'
    '^[^/]+/include/'
    '^[^/]+/src/'
    '^[^/]+/cmake/'
    '^[^/]+/locales/'
    '^[^/]+/example/'
    '^[^/]+/docs/'
    '^[^/]+/tests/'
  )

  for pattern in "${required_patterns[@]}"; do
    if ! tar_contains "$pattern"; then
      echo "[PACKAGER] ERROR: Missing required pattern in package: $pattern"
      errors=$((errors + 1))
    fi
  done

  # Verify extras/vcpkg is NOT included (should be obtained via configure script)
  if tar_contains '^[^/]+/extras/vcpkg/'; then
    echo "[PACKAGER] WARNING: vcpkg submodule found in package (should be excluded, use configure script instead)"
  fi

  # Verify extras/registry is NOT included
  if tar_contains '^[^/]+/extras/registry/'; then
    echo "[PACKAGER] ERROR: extras/registry found in package (must be excluded)"
    errors=$((errors + 1))
  fi

  if [[ $errors -eq 0 ]]; then
    echo "[PACKAGER] Source package validation: PASSED"
    return 0
  else
    echo "[PACKAGER] Source package validation: FAILED ($errors errors)"
    return 1
  fi
}

validate_binary_package() {
  local pkg_file="$1"
  local errors=0

  echo "[PACKAGER] Validating binary package: $(basename "$pkg_file")"

  # Binary package should have compiled files
  local has_binaries=false
  if unzip -l "$pkg_file" 2>/dev/null | grep -qE '\.(lib|a|so|dll|exe)$'; then
    has_binaries=true
  fi

  if [[ "$has_binaries" == "false" ]]; then
    echo "[PACKAGER] ERROR: No binary files found in package"
    errors=$((errors + 1))
  fi

  # Should have headers
  if ! unzip -l "$pkg_file" 2>/dev/null | grep -qE 'include/'; then
    echo "[PACKAGER] WARNING: No include directory found in package"
  fi

  # Should have cmake config
  if ! unzip -l "$pkg_file" 2>/dev/null | grep -qE '(cmake/|share/)'; then
    echo "[PACKAGER] WARNING: No cmake configuration found in package"
  fi

  # Should NOT have source .cpp files (except possibly examples)
  local src_count
  src_count=$(unzip -l "$pkg_file" 2>/dev/null | grep -cE 'src/.*\.cpp$' || true)
  if [[ "$src_count" -gt 0 ]]; then
    echo "[PACKAGER] WARNING: Found $src_count source .cpp files in package (should be pre-built)"
  fi

  if [[ $errors -eq 0 ]]; then
    echo "[PACKAGER] Binary package validation: PASSED"
    return 0
  else
    echo "[PACKAGER] Binary package validation: FAILED ($errors errors)"
    return 1
  fi
}

# Create source package for Unix
if [[ "$PACKAGE_TYPE" == "source" ]]; then
  PKG_NAME="i18n-redis-${VERSION}-source.tar.gz"
  PKG_PATH="$OUTPUT_DIR/$PKG_NAME"

  echo "[PACKAGER] Creating source package: $PKG_NAME"

  # Create filtered source package
  # Note: .github/scripts/ is excluded but we're running from there

  # Create temp staging directory to prepare files
  TEMP_STAGING=$(mktemp -d)
  mkdir -p "$TEMP_STAGING/i18n-redis-${VERSION}"

  # Copy all required files to staging
  cp "$PROJECT_ROOT/CMakeLists.txt" "$TEMP_STAGING/i18n-redis-${VERSION}/"
  cp "$PROJECT_ROOT/CMakePresets.json" "$TEMP_STAGING/i18n-redis-${VERSION}/"
  cp "$PROJECT_ROOT/vcpkg.json" "$TEMP_STAGING/i18n-redis-${VERSION}/"
  cp "$PROJECT_ROOT/vcpkg-configuration.json" "$TEMP_STAGING/i18n-redis-${VERSION}/"
  cp "$PROJECT_ROOT/configure" "$TEMP_STAGING/i18n-redis-${VERSION}/"
  cp "$PROJECT_ROOT/configure.ps1" "$TEMP_STAGING/i18n-redis-${VERSION}/"
  cp "$PROJECT_ROOT/LICENSE" "$TEMP_STAGING/i18n-redis-${VERSION}/"
  cp "$PROJECT_ROOT/.version" "$TEMP_STAGING/i18n-redis-${VERSION}/"

  # Copy package README as main README.md
  cp "$PROJECT_ROOT/.github/templates/README_PACKAGE.md" "$TEMP_STAGING/i18n-redis-${VERSION}/README.md"

  # Copy directories
  cp -r "$PROJECT_ROOT/include" "$TEMP_STAGING/i18n-redis-${VERSION}/"
  cp -r "$PROJECT_ROOT/src" "$TEMP_STAGING/i18n-redis-${VERSION}/"
  cp -r "$PROJECT_ROOT/cmake" "$TEMP_STAGING/i18n-redis-${VERSION}/"
  cp -r "$PROJECT_ROOT/locales" "$TEMP_STAGING/i18n-redis-${VERSION}/"
  cp -r "$PROJECT_ROOT/example" "$TEMP_STAGING/i18n-redis-${VERSION}/"
  cp -r "$PROJECT_ROOT/docs" "$TEMP_STAGING/i18n-redis-${VERSION}/"
  cp -r "$PROJECT_ROOT/tests" "$TEMP_STAGING/i18n-redis-${VERSION}/"

  # Create tar.gz from staging directory
  tar -czf "$PKG_PATH" -C "$TEMP_STAGING" "i18n-redis-${VERSION}"

  # Clean up staging
  rm -rf "$TEMP_STAGING"

  echo "[PACKAGER] Source package created: $PKG_PATH"
  ls -lh "$PKG_PATH"

  # Validate
  validate_source_package "$PKG_PATH"
  exit $?
fi

# Create binary package (for Windows builds)
if [[ "$PACKAGE_TYPE" == "binary" ]]; then
  INSTALL_DIR="${INSTALL_DIR:-$PROJECT_ROOT/out/install}"
  COMPILER="${COMPILER:-msvc}"
  VARIANT="${VARIANT:-static-release}"

  PKG_NAME="i18n-redis-${VERSION}-${COMPILER}-${VARIANT}.zip"
  PKG_PATH="$OUTPUT_DIR/$PKG_NAME"

  echo "[PACKAGER] Creating binary package: $PKG_NAME"
  echo "[PACKAGER] From install directory: $INSTALL_DIR"

  if [[ ! -d "$INSTALL_DIR" ]]; then
    echo "[PACKAGER] ERROR: Install directory not found: $INSTALL_DIR"
    exit 1
  fi

  # Create binary package
  (cd "$INSTALL_DIR" && zip -r "$PKG_PATH" .)

  echo "[PACKAGER] Binary package created: $PKG_PATH"
  ls -lh "$PKG_PATH"

  # Validate
  validate_binary_package "$PKG_PATH"
  exit $?
fi

echo "[PACKAGER] Unknown package type: $PACKAGE_TYPE"
echo "[PACKAGER] Usage: $0 [source|binary] [output_dir]"
exit 1
