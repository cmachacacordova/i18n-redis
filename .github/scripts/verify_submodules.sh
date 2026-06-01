#!/bin/bash
# Verify that git submodules are properly populated
# Usage: ./.github/scripts/verify_submodules.sh [path1] [path2] ...

set -euo pipefail

FAILED=0

for path in "$@"; do
  if [ ! -d "$path" ] || [ -z "$(ls -A "$path" 2>/dev/null)" ]; then
    echo "ERROR: submodule '$path' is missing or empty."
    FAILED=1
  else
    echo "OK: $path"
  fi
done

[ "$FAILED" -eq 0 ] || exit 1
