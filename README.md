# i18n-redis

A C++20 library for internationalisation (i18n) backed by Redis. Loads JSON
locale files from disk, stores each entry in Redis, and provides fast
key-based lookups with optional `{fmt}` format arguments.

## Table of Contents

- [Overview](#overview)
- [Requirements](#requirements)
- [Dependencies](#dependencies)
  - [System Packages](#system-packages)
  - [vcpkg](#vcpkg)
- [Building](#building)
  - [Quick Start](#quick-start)
  - [Using System Packages](#using-system-packages-1)
  - [Using vcpkg](#using-vcpkg-1)
  - [Manual CMake](#manual-cmake)
- [JSON Backend](#json-backend)
- [CMake Presets](#cmake-presets)
  - [Linux](#linux)
  - [Windows](#windows)
  - [macOS](#macos)
  - [Sanitizers / LTO](#sanitizers--lto)
- [Build Options](#build-options)
- [Usage](#usage)
  - [Example](#example)
  - [Locale File Format](#locale-file-format)
- [CMake Integration](#cmake-integration)
- [Testing](#testing)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Platform Notes](#platform-notes)
- [Versioning](#versioning)
- [License](#license)

## Overview

This library provides a translation service that:
- Loads locale files from disk (JSON format)
- Stores translations in Redis for fast lookups
- Supports parameterized translations using `{fmt}` syntax
- Works with multiple JSON backends (simdjson, yyjson)

## Requirements

| Tool | Minimum Version |
|------|-----------------|
| CMake | 3.25 |
| C++ Compiler | C++20 (GCC 11+, Clang 13+, MSVC 2022) |
| Unix Makefiles | any recent (Linux/macOS) |
| Ninja | any recent (Windows) |
| Redis Server | 5.0+ |

Optional:
| Tool | Purpose |
|------|---------|
| vcpkg | Dependency management (alternative to system packages) |

## Dependencies

| Library | Purpose | Repository |
|---------|---------|------------|
| [redis-plus-plus](https://github.com/sewenew/redis-plus-plus) | Redis client | https://github.com/sewenew/redis-plus-plus |
| [{fmt}](https://github.com/fmtlib/fmt) | String formatting | https://github.com/fmtlib/fmt |
| [simdjson](https://github.com/simdjson/simdjson) | JSON parsing | https://github.com/simdjson/simdjson |
| [yyjson](https://github.com/ibireme/yyjson) | JSON parsing (alternative) | https://github.com/ibireme/yyjson |
| [Catch2](https://github.com/catchorg/Catch2) | Testing framework | https://github.com/catchorg/Catch2 |

Two dependency management modes are supported:

| Mode | Best For |
|------|----------|
| **System packages** | Distribution packaging, CI/CD, minimal environments |
| **vcpkg** | Development, cross-platform builds, Windows |

### System Packages

Install dependencies via your system package manager:

**Ubuntu / Debian:**
```bash
sudo apt-get install -y cmake ninja-build g++ \
  libhiredis-dev libredis++-dev libfmt-dev \
  libyyjson-dev catch2

# simdjson may need manual installation:
# See https://github.com/simdjson/simdjson/releases
```

**Fedora / RHEL:**
```bash
sudo dnf install cmake ninja-build gcc-c++ \
  hiredis-devel fmt-devel yyjson-devel catch2-devel

# redis-plus-plus and simdjson may need manual build:
# https://github.com/sewenew/redis-plus-plus
# https://github.com/simdjson/simdjson
```

**Arch Linux:**
```bash
sudo pacman -S cmake ninja gcc clang hiredis fmt yyjson catch2

# From AUR:
yay -S redis-plus-plus simdjson
```

**macOS (Homebrew):**
```bash
brew install cmake ninja hiredis redis-plus-plus fmt yyjson simdjson catch2
```

### vcpkg

For automatic dependency management, use vcpkg:

**Using the bundled submodule (recommended for development):**
```bash
git submodule update --init extras/vcpkg
extras/vcpkg/bootstrap-vcpkg.sh  # Linux/macOS
# extras\vcpkg\bootstrap-vcpkg.bat  # Windows
export VCPKG_HOME=$(pwd)/extras/vcpkg
```

**Using your own vcpkg installation:**
```bash
git clone https://github.com/microsoft/vcpkg.git ~/vcpkg
~/vcpkg/bootstrap-vcpkg.sh
export VCPKG_HOME=~/vcpkg
```

## Building

### Quick Start

The `configure` scripts provide the easiest way to build:

```bash
# Linux / macOS - System packages
./configure -p linux-gcc-static-release

# Linux / macOS - With vcpkg
./configure -p linux-gcc-static-release --use-vcpkg

# Windows (PowerShell) - With vcpkg
.\configure.ps1 -Preset windows-msvc-static-release -UseVcpkg
```

### Using System Packages

```bash
# Configure and build
./configure -p linux-gcc-static-release

# Or manually:
cmake --preset linux-gcc-static-release
cmake --build --preset linux-gcc-static-release
```

### Using vcpkg

```bash
# Ensure VCPKG_HOME is set
export VCPKG_HOME=/path/to/vcpkg

# Configure and build
./configure -p linux-gcc-static-release --use-vcpkg
```

The script will:
1. Detect vcpkg from `VCPKG_HOME`
2. Initialize the submodule if needed
3. Bootstrap vcpkg if not already done
4. Pass the correct toolchain and features to CMake

### Manual CMake

**With system packages:**
```bash
cmake --preset linux-gcc-static-release
cmake --build --preset linux-gcc-static-release
```

**With vcpkg:**
```bash
cmake --preset linux-gcc-static-release \
  -DCMAKE_TOOLCHAIN_FILE="$VCPKG_HOME/scripts/buildsystems/vcpkg.cmake" \
  -DVCPKG_MANIFEST_FEATURES="simdjson"
cmake --build --preset linux-gcc-static-release
```

**With overlays (CI setup):**
```bash
cmake --preset linux-gcc-static-release \
  -DCMAKE_TOOLCHAIN_FILE="$VCPKG_HOME/scripts/buildsystems/vcpkg.cmake" \
  -DVCPKG_MANIFEST_FEATURES="simdjson" \
  -DVCPKG_OVERLAY_PORTS="$PWD/extras/registry/ports" \
  -DVCPKG_OVERLAY_TRIPLETS="$PWD/extras/registry/triplets"
```

## JSON Backend

The JSON backend is selected by the preset name:

| Preset Pattern | Backend | vcpkg Feature |
|----------------|---------|---------------|
| `<preset>` (base) | simdjson | `simdjson` |
| `<preset>-yyjson` | yyjson | `yyjson` |

Examples:
- `linux-gcc-static-release` → simdjson
- `linux-gcc-static-release-yyjson` → yyjson

## CMake Presets

Preset naming: `<platform>-<compiler>-<linkage>-<config>[-yyjson]`

All presets support both `simdjson` (base) and `yyjson` (append `-yyjson`) backends.

### Linux — GCC

| Preset | Linkage | Config | Notes |
|--------|---------|--------|-------|
| `linux-gcc-static-release` | static | Release | Production builds |
| `linux-gcc-shared-release` | shared | Release | Shared library |
| `linux-gcc-static-debug` | static | Debug | Development |
| `linux-gcc-shared-debug` | shared | Debug | Development |
| `linux-gcc-static-asan` | static | Debug | AddressSanitizer |
| `linux-gcc-static-ubsan` | static | Debug | UndefinedBehaviorSanitizer |
| `linux-gcc-static-release-lto` | static | Release | Link-time optimization |

### Linux — Clang

| Preset | Linkage | Config | Notes |
|--------|---------|--------|-------|
| `linux-clang-static-release` | static | Release | Production builds |
| `linux-clang-shared-release` | shared | Release | Shared library |
| `linux-clang-static-debug` | static | Debug | Development |
| `linux-clang-shared-debug` | shared | Debug | Development |
| `linux-clang-static-asan` | static | Debug | AddressSanitizer |
| `linux-clang-static-ubsan` | static | Debug | UndefinedBehaviorSanitizer |
| `linux-clang-static-release-lto` | static | Release | Link-time optimization |

### Windows — MSVC

| Preset | Linkage | Config | Notes |
|--------|---------|--------|-------|
| `windows-msvc-static-release` | static | Release | Production builds |
| `windows-msvc-shared-release` | shared | Release | Shared library |
| `windows-msvc-static-debug` | static | Debug | Development |
| `windows-msvc-shared-debug` | shared | Debug | Development |

### macOS — Clang

| Preset | Linkage | Config | Notes |
|--------|---------|--------|-------|
| `macos-clang-static-release` | static | Release | Production builds |
| `macos-clang-shared-release` | shared | Release | Shared library |
| `macos-clang-static-debug` | static | Debug | Development |
| `macos-clang-shared-debug` | shared | Debug | Development |

### All Available Variants

Every preset above has a corresponding `-yyjson` variant for the yyjson backend:
- `linux-gcc-static-release` → `linux-gcc-static-release-yyjson`
- `linux-clang-static-asan` → `linux-clang-static-asan-yyjson`
- `windows-msvc-static-debug` → `windows-msvc-static-debug-yyjson`
- etc.

For the complete list, see `CMakePresets.json`.

## Build Options

| Variable | Default | Description |
|----------|---------|-------------|
| `I18N_REDIS_JSON_BACKEND` | `simdjson` | JSON backend: `simdjson` or `yyjson` |
| `BUILD_SHARED_LIBS` | `OFF` | Build shared library |
| `I18N_REDIS_BUILD_EXAMPLES` | `OFF` | Build example application |
| `I18N_REDIS_BUILD_TESTS` | `OFF` | Build test suite |
| `I18N_REDIS_ENABLE_LTO` | `ON` (Release) | Enable IPO/LTO |
| `I18N_REDIS_ENABLE_ASAN` | `OFF` | Enable AddressSanitizer |
| `I18N_REDIS_ENABLE_UBSAN` | `OFF` | Enable UndefinedBehaviourSanitizer |

vcpkg-specific:
| Variable | Description |
|----------|-------------|
| `VCPKG_MANIFEST_FEATURES` | Features to install: `simdjson`, `yyjson`, `tests` |
| `CMAKE_TOOLCHAIN_FILE` | Path to vcpkg.cmake |

## Usage

### Example

```cpp
#include "i18n/redis/RedisTranslationProvider.h"
#include "i18n/Translation.h"

// Create provider
auto provider = std::make_unique<i18n::RedisTranslationProvider>("localhost", 6379);
i18n::Translation t(std::move(provider), "en");

// Load locale files into Redis
t.store(std::filesystem::current_path().string(), {"en", "es"});

// Translate using default locale
std::string msg = t.translate("greeting");              // "Hello!"

// Translate with explicit locale
std::string msg2 = t.translate("greeting", "es");      // "¡Hola!"

// Translate with formatting (uses default locale)
std::string msg3 = t.translate("welcome", "Alice");    // "Welcome, Alice!"

// Translate with formatting and explicit locale
std::string msg4 = t.translate("welcome", "es", "Alice"); // "¡Bienvenida, Alice!"
```

**Note:** The `Translation` constructor now defaults to `"en"` if no locale is specified:
```cpp
i18n::Translation t(std::move(provider)); // Uses "en" as default locale
```

**Advanced Redis connection:** For custom Redis connection options, use the connection options constructor:
```cpp
sw::redis::ConnectionOptions conn_opts;
conn_opts.host = "localhost";
conn_opts.port = 6379;
conn_opts.password = "secret";

sw::redis::ConnectionPoolOptions pool_opts;
pool_opts.size = 10;

auto provider = std::make_unique<i18n::RedisTranslationProvider>(conn_opts, pool_opts);
```

### Locale File Format

Place JSON files in `locales/<locale>/` directories:

```json
[
  {
    "id": "greeting",
    "value": "Hello, {}!",
    "category": "General",
    "creationDate": "2024-01-01",
    "modificationDate": "2024-06-01",
    "modificationVersion": 1
  }
]
```

**Required fields:**
- `id`: Translation identifier (must not contain colons)
- `value`: Translated string (may contain `{fmt}` placeholders)
- `category`: Translation category
- `creationDate`: ISO 8601 date string
- `modificationDate`: ISO 8601 date string
- `modificationVersion`: Integer version number

Redis keys: `i18n:<locale>:<id>` (e.g., `i18n:en:greeting`)

## CMake Integration

After installation:

```cmake
find_package(i18n-redis CONFIG REQUIRED)
target_link_libraries(my-app PRIVATE i18n-redis::i18n-redis)
```

Install:
```bash
cmake --install out/build --prefix /usr/local
```

## Testing

```bash
# Build with tests
./configure -p linux-gcc-static-debug

# Run tests
ctest --test-dir out/build --output-on-failure
```

Tests use Catch2 framework and verify:
- Configuration key formatting
- Translation lookup functionality
- JSON parsing for both simdjson and yyjson backends

## Project Structure

```
i18n-redis/
├── CMakeLists.txt              # Main build configuration
├── CMakePresets.json           # Build presets
├── vcpkg.json                  # vcpkg manifest
├── configure                   # Unix build helper
├── configure.ps1               # Windows build helper
├── cmake/                      # CMake modules
│   └── Modules/
│       ├── Dependencies.cmake
│       └── Targets.cmake
├── include/i18n/               # Public headers
│   ├── Translation.h           # Main facade class
│   ├── TranslationProvider.h   # Abstract provider interface
│   ├── Configuration.h         # Configuration constants
│   └── redis/RedisTranslationProvider.h  # Redis implementation
├── src/                        # Implementation files
│   ├── Translation.cpp
│   ├── TranslationProvider.cpp
│   └── RedisTranslationProvider.cpp
├── tests/                      # Test suite
│   ├── Main.cpp
│   └── TestTranslationKey.cpp
├── example/                    # Example application
├── docs/                       # Documentation
│   └── api.md                  # API reference
├── locales/                    # Sample locale files
└── extras/                     # vcpkg and registry (submodules)
    ├── vcpkg/
    └── registry/
```

## Troubleshooting

### Dependencies Not Found

**Check installation:**
```bash
# Ubuntu/Debian
dpkg -l | grep -E "hiredis|fmt|simdjson|yyjson"

# Fedora/RHEL
rpm -qa | grep -E "hiredis|fmt|simdjson|yyjson"

# Arch
pacman -Q | grep -E "hiredis|fmt|simdjson|yyjson"
```

**Custom paths:**
```bash
cmake --preset linux-gcc-static-release \
  -DCMAKE_PREFIX_PATH="/custom/path"
```

### vcpkg Issues

**Submodule not initialized:**
```bash
git submodule update --init extras/vcpkg
```

**Verify toolchain:**
```bash
cmake --preset linux-gcc-static-release \
  -DCMAKE_TOOLCHAIN_FILE="$VCPKG_HOME/scripts/buildsystems/vcpkg.cmake" \
  -DVCPKG_VERBOSE=ON
```

### Redis Connection

Verify Redis is running:
```bash
redis-cli ping  # Should return PONG
```

## Platform Notes

- **Linux**: GCC and Clang fully supported. System packages recommended for production builds.
- **Windows**: MSVC recommended. vcpkg is the easiest way to manage dependencies.
- **macOS**: Clang via Xcode or Homebrew. Both system packages and vcpkg work well.

## Versioning

| Type | Format | Example |
|------|--------|---------|
| Release | `X.Y.Z-RELEASE` | `0.3.2-RELEASE` |
| Snapshot | `X.Y.Z-<hash>-SNAPSHOT` | `0.3.2-abc1234-SNAPSHOT` |

## License

See [LICENSE](LICENSE).
