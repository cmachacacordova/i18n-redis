#!/usr/bin/env bash

set -euo pipefail

printUsage() {
  echo "Usage: $0 <snapshot|release> [version]"
  echo ""
  echo "Arguments:"
  echo "  snapshot    Create a snapshot version (X.Y.Z-<git-hash>-SNAPSHOT)"
  echo "  release     Create a release version (X.Y.Z-RELEASE)"
  echo "  version     Optional version (e.g., 1.2.3). If omitted, reads from CMakeLists.txt"
  echo ""
  echo "Examples:"
  echo "  $0 snapshot           # Creates 0.3.2-abc1234-SNAPSHOT"
  echo "  $0 release            # Creates 0.3.2-RELEASE"
  echo "  $0 snapshot 1.2.3     # Creates 1.2.3-abc1234-SNAPSHOT"
  echo "  $0 release 2.0.0      # Creates 2.0.0-RELEASE"
  exit 1
}

if [[ $# -lt 1 ]]; then
  printUsage
fi

TYPE=$1
shift

if [[ "$TYPE" != "snapshot" && "$TYPE" != "release" ]]; then
  echo "Error: Type must be 'snapshot' or 'release'"
  printUsage
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CMAKE_FILE="$PROJECT_DIR/CMakeLists.txt"
VCPKG_FILE="$PROJECT_DIR/vcpkg.json"

if [[ $# -ge 1 ]]; then
  VERSION=$1
  if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Version must be in format X.Y.Z (e.g., 1.2.3)"
    exit 1
  fi
else
  if [[ ! -f "$CMAKE_FILE" ]]; then
    echo "Error: CMakeLists.txt not found at $CMAKE_FILE"
    exit 1
  fi
  VERSION=$(grep -oP 'project\s*\(\s*\w+\s+VERSION\s+\K[0-9]+\.[0-9]+\.[0-9]+' "$CMAKE_FILE" || true)
  if [[ -z "$VERSION" ]]; then
    echo "Error: Could not extract version from CMakeLists.txt"
    exit 1
  fi
fi

if [[ "$TYPE" == "snapshot" ]]; then
  GIT_HASH=$(git -C "$PROJECT_DIR" rev-parse --short=7 HEAD 2>/dev/null || echo "unknown")
  FULL_VERSION="${VERSION}-${GIT_HASH}-SNAPSHOT"
else
  FULL_VERSION="${VERSION}-RELEASE"
fi

echo "Generating version: $FULL_VERSION"

updateCMakeLists() {
  sed -i.bak "s/project(\s*\([a-zA-Z0-9_-]*\)\s*VERSION\s*[0-9]\+\.[0-9]\+\.[0-9]\+/project(\1 VERSION $VERSION/" "$CMAKE_FILE"
  rm -f "$CMAKE_FILE.bak"
  echo "Updated CMakeLists.txt: VERSION $VERSION"
}

updateVcpkgJson() {
  if [[ ! -f "$VCPKG_FILE" ]]; then
    echo "Warning: vcpkg.json not found at $VCPKG_FILE"
    return 0
  fi

  local tmp_file="${VCPKG_FILE}.tmp"

  # Remove old "version" field and ensure "version-string" is set correctly
  awk -v ver="$FULL_VERSION" '
    /^\s*"version"\s*:/ { next }
    /^\s*"version-string"\s*:/ {
      print "  \"version-string\": \"" ver "\","
      next
    }
    { print }
  ' "$VCPKG_FILE" > "$tmp_file"

  # Check if version-string was found and added; if not, add it after the name field
  if ! grep -q '"version-string"' "$tmp_file"; then
    awk -v ver="$FULL_VERSION" '
      /^\s*"name"\s*:/ {
        print
        print "  \"version-string\": \"" ver "\","
        next
      }
      { print }
    ' "$tmp_file" > "${tmp_file}.2"
    mv "${tmp_file}.2" "$tmp_file"
  fi

  mv "$tmp_file" "$VCPKG_FILE"
  echo "Updated vcpkg.json: version-string = $FULL_VERSION"
}

updateCMakeLists
updateVcpkgJson

echo ""
echo "Version updated successfully!"
echo "  Base version: $VERSION"
echo "  Full version: $FULL_VERSION"
echo ""

if ! git -C "$PROJECT_DIR" diff --quiet; then
  git -C "$PROJECT_DIR" add CMakeLists.txt vcpkg.json
  git -C "$PROJECT_DIR" commit -m "chore: bump version to $FULL_VERSION"
  echo "Committed version changes"
fi

TAG_NAME="$FULL_VERSION"
if git -C "$PROJECT_DIR" rev-parse "$TAG_NAME" >/dev/null 2>&1; then
  echo "Warning: Tag $TAG_NAME already exists"
else
  git -C "$PROJECT_DIR" tag -a "$TAG_NAME" -m "Version $FULL_VERSION"
  echo "Created tag: $TAG_NAME"
fi

echo ""
echo "Pushing to origin..."
git -C "$PROJECT_DIR" push origin HEAD
git -C "$PROJECT_DIR" push origin "$TAG_NAME"

echo ""
echo "Version $FULL_VERSION released successfully!"
echo "CI will build and create GitHub Release automatically."
