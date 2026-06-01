#!/bin/bash
# Validate release packages
# Usage: ./validate_release_packages.sh <release_directory>

set -euo pipefail

RELEASE_DIR="${1:-release}"

if [[ ! -d "$RELEASE_DIR" ]]; then
  echo "[VALIDATE] ERROR: Release directory not found: $RELEASE_DIR"
  exit 1
fi

echo "[VALIDATE] Validating release packages in: $RELEASE_DIR"

ERRORS=0

# Validate source packages (should have configure script)
for pkg in "$RELEASE_DIR"/*-source.tar.gz; do
  if [[ -f "$pkg" ]]; then
    echo "[VALIDATE] Checking source package: $(basename "$pkg")"

    # Verify no excluded files
    if tar -tzf "$pkg" 2>/dev/null | grep -qE '(\.vscode/|\.windsurf/|\.github/|out/|vcpkg_installed/|extras/registry)'; then
      echo "[VALIDATE] ERROR: Found excluded directories in $(basename "$pkg")"
      tar -tzf "$pkg" 2>/dev/null | grep -E '(\.vscode/|\.windsurf/|\.github/|out/|vcpkg_installed/|extras/registry)'
      ERRORS=$((ERRORS + 1))
    fi

    # Verify configure script exists
    if ! tar -tzf "$pkg" 2>/dev/null | grep -qE 'configure$'; then
      echo "[VALIDATE] ERROR: configure script not found in $(basename "$pkg")"
      ERRORS=$((ERRORS + 1))
    fi

    if [[ $ERRORS -eq 0 ]]; then
      echo "[VALIDATE] Source package validation: PASSED"
    fi
  fi
done

# Validate Unix binary packages (should have .a libraries)
for pkg in "$RELEASE_DIR"/linux-*.tar.gz; do
  if [[ -f "$pkg" ]]; then
    echo "[VALIDATE] Checking Unix binary package: $(basename "$pkg")"

    # Verify it has library files
    if ! tar -tzf "$pkg" 2>/dev/null | grep -qE '\.(a|so)$'; then
      echo "[VALIDATE] ERROR: No library files (.a, .so) found in $(basename "$pkg")"
      ERRORS=$((ERRORS + 1))
    fi

    # Verify no source files or build configs
    if tar -tzf "$pkg" 2>/dev/null | grep -qE '(src/.*\.cpp$|\.github/|CMakeLists\.txt|CMakePresets\.json|vcpkg\.json|vcpkg-configuration\.json|configure$|configure\.ps1$)'; then
      echo "[VALIDATE] ERROR: Found source/build files in binary package $(basename "$pkg")"
      tar -tzf "$pkg" 2>/dev/null | grep -E '(src/.*\.cpp$|\.github/|CMakeLists\.txt|CMakePresets\.json|vcpkg\.json|vcpkg-configuration\.json|configure$|configure\.ps1$)'
      ERRORS=$((ERRORS + 1))
    fi

    # Verify README.md exists
    if ! tar -tzf "$pkg" 2>/dev/null | grep -qE '^README\.md$'; then
      echo "[VALIDATE] ERROR: README.md not found in $(basename "$pkg")"
      ERRORS=$((ERRORS + 1))
    fi

    if [[ $ERRORS -eq 0 ]]; then
      echo "[VALIDATE] Unix binary package validation: PASSED"
    fi
  fi
done

# Validate Windows binary packages
for pkg in "$RELEASE_DIR"/*.zip; do
  if [[ -f "$pkg" ]]; then
    echo "[VALIDATE] Checking Windows binary package: $(basename "$pkg")"

    # Verify it has binary files
    if ! unzip -l "$pkg" 2>/dev/null | grep -qE '\.(lib|dll|exe)$'; then
      echo "[VALIDATE] ERROR: No binary files (.lib, .dll, .exe) found in $(basename "$pkg")"
      ERRORS=$((ERRORS + 1))
    fi

    # Verify no source files or build configs
    if unzip -l "$pkg" 2>/dev/null | grep -qE '(src/.*\.cpp$|extras/registry|\.github/|vcpkg_installed/|out/|CMakeLists\.txt|CMakePresets\.json|vcpkg\.json|vcpkg-configuration\.json|configure$|configure\.ps1$)'; then
      echo "[VALIDATE] ERROR: Found source or internal build files in $(basename "$pkg")"
      unzip -l "$pkg" 2>/dev/null | grep -E '(src/.*\.cpp$|extras/registry|\.github/|vcpkg_installed/|out/|CMakeLists\.txt|CMakePresets\.json|vcpkg\.json|vcpkg-configuration\.json|configure$|configure\.ps1$)'
      ERRORS=$((ERRORS + 1))
    fi

    # Verify README.md exists
    if ! unzip -l "$pkg" 2>/dev/null | grep -qE '^README\.md$'; then
      echo "[VALIDATE] ERROR: README.md not found in $(basename "$pkg")"
      ERRORS=$((ERRORS + 1))
    fi

    if [[ $ERRORS -eq 0 ]]; then
      echo "[VALIDATE] Windows binary package validation: PASSED"
    fi
  fi
done

if [[ $ERRORS -eq 0 ]]; then
  echo "[VALIDATE] All packages validated successfully"
  exit 0
else
  echo "[VALIDATE] Validation failed with $ERRORS errors"
  exit 1
fi
