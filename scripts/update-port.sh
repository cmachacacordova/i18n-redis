#!/bin/bash
# Update the vcpkg port in extras/registry from the main project
# Usage: ./scripts/update-port.sh [version] [ref]
# Examples:
#   ./scripts/update-port.sh              # uses version from vcpkg.json
#   ./scripts/update-port.sh 0.4.0          # specific version
#   ./scripts/update-port.sh 0.4.0 0.4.0     # version and git ref

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REGISTRY_DIR="${PROJECT_ROOT}/extras/registry"
PORT_DIR="${REGISTRY_DIR}/ports/i18n-redis"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get version from project vcpkg.json if not provided
get_project_version() {
    local vcpkg_file="${PROJECT_ROOT}/vcpkg.json"
    if [[ -f "$vcpkg_file" ]]; then
        grep -o '"version[^"]*": "[^"]*"' "$vcpkg_file" | head -1 | sed 's/.*: "\([^"]*\)".*/\1/'
    else
        log_error "Project vcpkg.json not found"
        exit 1
    fi
}

# Calculate SHA512 for a GitHub release tarball
calculate_sha512() {
    local repo="$1"
    local ref="$2"
    local url="https://github.com/${repo}/archive/refs/tags/${ref}.tar.gz"
    
    log_info "Downloading ${url}..." >&2
    local temp_file
    temp_file=$(mktemp)
    
    if ! curl -sL "$url" -o "$temp_file"; then
        log_error "Failed to download tarball" >&2
        rm -f "$temp_file"
        exit 1
    fi
    
    local sha512
    sha512=$(sha512sum "$temp_file" | cut -d' ' -f1)
    rm -f "$temp_file"
    
    echo "$sha512"
}

# Update portfile.cmake with new version and SHA
update_portfile() {
    local version="$1"
    local ref="$2"
    local sha512="$3"
    local portfile="${PORT_DIR}/portfile.cmake"
    
    log_info "Updating ${portfile}..."
    
    # Update REF
    sed -i -E "s|REF v?[0-9]+\.[0-9]+\.[0-9]+[^[:space:]]*|REF ${ref}|" "$portfile"
    
    # Update SHA512
    sed -i -E "s|SHA512 [a-f0-9]+|SHA512 ${sha512}|" "$portfile"
    
    log_info "Updated portfile.cmake: REF=${ref}, SHA512=${sha512:0:16}..."
}

# Update vcpkg.json version (but keep other settings)
update_vcpkg_json() {
    local version="$1"
    local vcpkg_json="${PORT_DIR}/vcpkg.json"
    
    log_info "Updating ${vcpkg_json}..."
    
    # Update version field only
    sed -i -E "s/\"version\": \"[^\"]+\"/\"version\": \"${version}\"/" "$vcpkg_json"
    
    log_info "Updated vcpkg.json: version=${version}"
}

# Show usage
usage() {
    echo "Usage: $0 [version] [ref]"
    echo ""
    echo "Examples:"
    echo "  $0                    # Auto-detect version from project vcpkg.json"
    echo "  $0 0.4.0              # Update to version 0.4.0"
    echo "  $0 0.4.0 0.4.0        # Version 0.4.0 with git ref 0.4.0"
    echo "  $0 0.4.0 1a2b3c4d     # Version 0.4.0 with commit hash"
    exit 1
}

main() {
    local version="${1:-}"
    local ref="${2:-}"
    
    # Check if port directory exists
    if [[ ! -d "$PORT_DIR" ]]; then
        log_error "Port directory not found: ${PORT_DIR}"
        log_error "Make sure extras/registry submodule is initialized"
        exit 1
    fi
    
    # Auto-detect version if not provided
    if [[ -z "$version" ]]; then
        version=$(get_project_version)
        log_info "Auto-detected version: ${version}"
    fi
    
    # Default ref to version
    if [[ -z "$ref" ]]; then
        ref="${version}"
    fi
    
    log_info "Updating port to version ${version} (ref: ${ref})..."
    
    # Verify tag exists on GitHub
    log_info "Checking GitHub tag..."
    if ! git ls-remote --tags "https://github.com/cmachacacordova/i18n-redis.git" "refs/tags/${ref}" | grep -q .; then
        log_warn "Tag ${ref} may not exist on GitHub yet"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Calculate SHA512
    local sha512
    sha512=$(calculate_sha512 "cmachacacordova/i18n-redis" "$ref")
    
    # Update files
    update_vcpkg_json "$version"
    update_portfile "$version" "$ref" "$sha512"
    
    log_info "Port updated successfully!"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Review changes in ${REGISTRY_DIR}"
    log_info "  2. Test: vcpkg install i18n-redis --overlay-ports=${REGISTRY_DIR}/ports"
    log_info "  3. Commit and push changes to the registry repo"
}

# Handle help
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
fi

main "$@"
