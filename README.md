# i18n-redis

A C++20 library for internationalisation (i18n) backed by Redis. Loads JSON
locale files from disk, stores each entry in Redis, and provides fast
key-based lookups with optional `{fmt}` format arguments.

## Table of contents

- [Requirements](#requirements)
- [Dependencies](#dependencies)
- [Setup](#setup)
  - [1 — Install vcpkg](#1--install-vcpkg)
  - [2 — Set VCPKG_HOME persistently](#2--set-vcpkg_home-persistently)
  - [3 — Install a compiler and Ninja](#3--install-a-compiler-and-ninja)
- [Building](#building)
  - [Quick start (convenience script)](#quick-start-convenience-script)
  - [Manual (cmake --preset)](#manual-cmake---preset)
- [JSON backend](#json-backend)
  - [Choosing the backend in VS Code](#choosing-the-backend-in-vs-code)
- [CMake Presets](#cmake-presets)
  - [Linux](#linux)
  - [Windows (MSVC)](#windows-msvc)
  - [macOS (Clang)](#macos-clang)
  - [Sanitizers / LTO](#sanitizers--lto)
- [Build options](#build-options)
- [Usage](#usage)
  - [Locale file format](#locale-file-format)
- [CMake integration](#cmake-integration)
- [Running tests](#running-tests)
- [Project structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Platform notes](#platform-notes)
- [Versioning](#versioning)
- [License](#license)

## Requirements

| Tool | Minimum version |
|------|----------------|
| CMake | 3.25 |
| C++ compiler | C++20 (GCC 11+, Clang 13+, MSVC 2022) |
| Ninja | any recent |
| vcpkg | any recent |

## Dependencies

All dependencies are managed automatically by **vcpkg** via the `vcpkg.json`
manifest. No manual installation is required.

| Library | Purpose | vcpkg feature |
|---------|---------|---------------|
| [redis-plus-plus](https://github.com/sewenew/redis-plus-plus) | Redis client | *(core)* |
| [{fmt}](https://github.com/fmtlib/fmt) | String formatting | *(core)* |
| [simdjson](https://github.com/simdjson/simdjson) | JSON parsing (default) | `simdjson` |
| [yyjson](https://github.com/ibireme/yyjson) | JSON parsing (alternative) | `yyjson` |
| [Catch2](https://github.com/catchorg/Catch2) | Test framework | `tests` |

## Setup

### 1 — Install vcpkg

**Option A — use the bundled submodule (recommended)**

The repository ships vcpkg as a git submodule under `extras/vcpkg`.
No external clone needed — just initialise the submodule and bootstrap:

```bash
git submodule update --init extras/vcpkg
extras/vcpkg/bootstrap-vcpkg.sh     # Linux / macOS
# extras\vcpkg\bootstrap-vcpkg.bat  # Windows
export VCPKG_HOME=$(pwd)/extras/vcpkg
```

**Option B — bring your own vcpkg**

```bash
git clone https://github.com/microsoft/vcpkg.git ~/vcpkg
~/vcpkg/bootstrap-vcpkg.sh
export VCPKG_HOME=~/vcpkg
```

### 2 — Set VCPKG_HOME persistently

Add the export to your shell profile so every new session picks it up:

```bash
# Bundled submodule — absolute path required
echo 'export VCPKG_HOME=/path/to/i18n-redis/extras/vcpkg' >> ~/.bashrc

# External clone
echo 'export VCPKG_HOME=~/vcpkg' >> ~/.bashrc
```

On Windows set `VCPKG_HOME` permanently via *System Properties → Environment Variables*.

### 3 — Install a compiler and Ninja

**Ubuntu / Debian:**
```bash
sudo apt-get install -y cmake ninja-build g++ clang
```

**Fedora / RHEL:**
```bash
sudo dnf install cmake ninja-build gcc-c++ clang
```

**macOS:**
```bash
brew install cmake ninja
```

**Windows:** Install Visual Studio 2022 with the *C++ Desktop* workload.

## Building

### Quick start (convenience script)

```bash
# Linux / macOS
./scripts/build_project.sh static release          # GCC + simdjson
./scripts/build_project.sh static release clang    # Clang + simdjson
./scripts/build_project.sh static release gcc yyjson   # GCC + yyjson
./scripts/build_project.sh shared debug clang yyjson   # Clang + yyjson

# Windows (cmd)
scripts\build_project.bat static release           # MSVC + simdjson
scripts\build_project.bat static release yyjson    # MSVC + yyjson
```

If `VCPKG_HOME` is not set the script automatically initialises the
`extras/vcpkg` submodule and bootstraps vcpkg before building.
vcpkg then installs the selected JSON backend via the `vcpkg.json` manifest.

### Manual (cmake --preset)

```bash
# Configure + build — simdjson (default)
cmake --preset linux-gcc-static-release
cmake --build --preset linux-gcc-static-release

# Configure + build — yyjson
cmake --preset linux-gcc-static-release-yyjson
cmake --build --preset linux-gcc-static-release-yyjson
```

## JSON backend

The JSON backend is selected **per preset**. Both `VCPKG_MANIFEST_FEATURES`
and `I18N_REDIS_JSON_BACKEND` are set automatically — no extra `-D` flags
needed.

| Preset suffix | Backend | vcpkg feature |
|---------------|---------|---------------|
| *(none)* | simdjson | `simdjson` |
| `-yyjson` | yyjson | `yyjson` |

### Choosing the backend in VS Code

The CMake Tools extension lists every non-hidden preset. Select the one you
want from the status bar or the *CMake: Select Configure Preset* command:

```
Linux / GCC / Static / Debug [simdjson]
Linux / GCC / Static / Debug [yyjson]
Linux / Clang / Static / Release [simdjson]
Linux / Clang / Static / Release [yyjson]
...
```

The extension will configure, install dependencies via vcpkg, and build with
the chosen backend automatically.

## CMake Presets

Preset names follow the pattern `<platform>-<compiler>-<type>-<config>[-yyjson]`.
Every preset exists in both a `simdjson` (default) and `yyjson` variant.

### Linux

| Preset | Compiler | Type | Config | Backend |
|--------|----------|------|--------|---------|
| `linux-gcc-static-debug` | GCC | static | Debug | simdjson |
| `linux-gcc-static-debug-yyjson` | GCC | static | Debug | yyjson |
| `linux-gcc-static-release` | GCC | static | Release | simdjson |
| `linux-gcc-static-release-yyjson` | GCC | static | Release | yyjson |
| `linux-gcc-shared-debug` | GCC | shared | Debug | simdjson |
| `linux-gcc-shared-debug-yyjson` | GCC | shared | Debug | yyjson |
| `linux-gcc-shared-release` | GCC | shared | Release | simdjson |
| `linux-gcc-shared-release-yyjson` | GCC | shared | Release | yyjson |
| `linux-clang-static-debug` | Clang | static | Debug | simdjson |
| `linux-clang-static-debug-yyjson` | Clang | static | Debug | yyjson |
| `linux-clang-static-release` | Clang | static | Release | simdjson |
| `linux-clang-static-release-yyjson` | Clang | static | Release | yyjson |
| `linux-clang-shared-debug` | Clang | shared | Debug | simdjson |
| `linux-clang-shared-debug-yyjson` | Clang | shared | Debug | yyjson |
| `linux-clang-shared-release` | Clang | shared | Release | simdjson |
| `linux-clang-shared-release-yyjson` | Clang | shared | Release | yyjson |

### Windows (MSVC)

| Preset | Type | Config | Backend |
|--------|------|--------|---------|
| `windows-msvc-static-debug` | static | Debug | simdjson |
| `windows-msvc-static-debug-yyjson` | static | Debug | yyjson |
| `windows-msvc-static-release` | static | Release | simdjson |
| `windows-msvc-static-release-yyjson` | static | Release | yyjson |
| `windows-msvc-shared-debug` | shared | Debug | simdjson |
| `windows-msvc-shared-debug-yyjson` | shared | Debug | yyjson |
| `windows-msvc-shared-release` | shared | Release | simdjson |
| `windows-msvc-shared-release-yyjson` | shared | Release | yyjson |

### macOS (Clang)

| Preset | Type | Config | Backend |
|--------|------|--------|---------|
| `macos-clang-static-debug` | static | Debug | simdjson |
| `macos-clang-static-debug-yyjson` | static | Debug | yyjson |
| `macos-clang-static-release` | static | Release | simdjson |
| `macos-clang-static-release-yyjson` | static | Release | yyjson |
| `macos-clang-shared-debug` | shared | Debug | simdjson |
| `macos-clang-shared-debug-yyjson` | shared | Debug | yyjson |
| `macos-clang-shared-release` | shared | Release | simdjson |
| `macos-clang-shared-release-yyjson` | shared | Release | yyjson |

### Sanitizers / LTO

| Preset | Notes | Backend |
|--------|-------|---------|
| `linux-clang-static-asan` | AddressSanitizer | simdjson |
| `linux-clang-static-asan-yyjson` | AddressSanitizer | yyjson |
| `linux-clang-static-ubsan` | UndefinedBehaviourSanitizer | simdjson |
| `linux-clang-static-ubsan-yyjson` | UndefinedBehaviourSanitizer | yyjson |
| `linux-gcc-static-asan` | AddressSanitizer | simdjson |
| `linux-gcc-static-asan-yyjson` | AddressSanitizer | yyjson |
| `linux-gcc-static-ubsan` | UndefinedBehaviourSanitizer | simdjson |
| `linux-gcc-static-ubsan-yyjson` | UndefinedBehaviourSanitizer | yyjson |
| `linux-clang-static-release-lto` | Release + LTO | simdjson |
| `linux-clang-static-release-lto-yyjson` | Release + LTO | yyjson |
| `linux-gcc-static-release-lto` | Release + LTO | simdjson |
| `linux-gcc-static-release-lto-yyjson` | Release + LTO | yyjson |

## Build options

| Variable | Default | Description |
|----------|---------|-------------|
| `I18N_REDIS_JSON_BACKEND` | `simdjson` | JSON backend: `simdjson` or `yyjson` (set by preset) |
| `VCPKG_MANIFEST_FEATURES` | `simdjson` | vcpkg feature to install (set by preset) |
| `BUILD_SHARED_LIBS` | `OFF` | Build shared library |
| `I18N_REDIS_BUILD_EXAMPLES` | `OFF` | Build example application |
| `I18N_REDIS_BUILD_TESTS` | `OFF` | Build test suite |
| `I18N_REDIS_ENABLE_LTO` | `ON` | Enable IPO/LTO for Release |
| `I18N_REDIS_ENABLE_ASAN` | `OFF` | Enable AddressSanitizer |
| `I18N_REDIS_ENABLE_UBSAN` | `OFF` | Enable UndefinedBehaviourSanitizer |

## Usage

```cpp
#include "i18n/redis/translation_provider.h"
#include "i18n/translation.h"

auto provider = std::make_unique<i18n::RedisTranslationProvider>("localhost", 6379);
i18n::Translation t(std::move(provider), "en");

t.store(std::filesystem::current_path().string(), {"en", "es"});

std::string msg  = t.translate("greeting");
std::string msg2 = t.translate("greeting", "es");
std::string msg3 = t.translate("welcome", "en", "Alice");
```

### Locale file format

Each locale directory (`locales/<locale>/`) may contain any number of `.json`
files. Each file must be a JSON array:

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

Redis keys follow the pattern `i18n:<locale>:<id>` (e.g. `i18n:en:greeting`).

## CMake integration

After installing with `cmake --install`:

```cmake
find_package(i18n-redis CONFIG REQUIRED)
target_link_libraries(my-app PRIVATE i18n-redis::i18n-redis)
```

### Install

```bash
cmake --preset linux-gcc-static-release
cmake --build --preset linux-gcc-static-release
cmake --install out/build --prefix /usr/local
```

## Running tests

```bash
cmake --preset linux-gcc-static-debug
cmake --build --preset linux-gcc-static-debug
ctest --test-dir out/build --output-on-failure
```

## Project structure

```
i18n-redis/
├── .clang-format                 # clang-format style configuration
├── .clangd                       # clangd LSP settings
├── .actrc                        # act (local GitHub Actions runner) config
├── .gitmodules                   # git submodules declaration
├── CMakeLists.txt
├── CMakePresets.json
├── LICENSE
├── vcpkg.json                    # vcpkg manifest — declares all dependencies
├── vcpkg-configuration.json      # vcpkg baseline and port configuration
├── vcpkg_installed/              # vcpkg installed packages (generated, gitignored)
├── .github/
│   └── workflows/
│       ├── ci.yml
│       └── release.yml
├── .vscode/
│   └── settings.json             # CMake Tools, clangd, clang-format settings
├── cmake/
│   └── i18n-redisConfig.cmake.in
├── docs/
│   └── api.md
├── example/
│   └── main.cpp
├── extras/
│   └── vcpkg/                    # vcpkg submodule (git submodule update --init extras/vcpkg)
├── include/
│   └── i18n/
│       ├── configuration.h
│       ├── translation.h
│       ├── translation_provider.h
│       └── redis/
│           └── translation_provider.h
├── locales/
│   └── en/
│       └── messages.json
├── scripts/
│   ├── cmake/
│   │   ├── Dependencies.cmake
│   │   └── Targets.cmake
│   ├── build_project.sh
│   ├── build_project.bat
│   └── version.sh
├── src/
│   ├── redis_translation_provider.cpp
│   ├── translation.cpp
│   └── translation_provider.cpp
└── tests/
    ├── CMakeLists.txt
    ├── main.cpp
    └── test_translation_key.cpp
```

## Troubleshooting

### VCPKG_HOME is not set

`VCPKG_HOME` is **optional** — when unset, `build_project.sh` / `build_project.bat`
automatically initialises the `extras/vcpkg` submodule and bootstraps vcpkg.

To set it persistently:

```bash
# Bundled submodule
export VCPKG_HOME=/absolute/path/to/i18n-redis/extras/vcpkg

# External clone
export VCPKG_HOME=~/vcpkg

# Windows (cmd) — bundled submodule
set VCPKG_HOME=%CD%\extras\vcpkg
```

### vcpkg submodule not initialised (manual cmake workflow)

If using `cmake --preset` directly without the convenience script:

```bash
git submodule update --init extras/vcpkg
extras/vcpkg/bootstrap-vcpkg.sh
export VCPKG_HOME=$(pwd)/extras/vcpkg
```

### CMake cannot find packages after vcpkg install

Verify that `VCPKG_HOME` is set and that the toolchain file is being picked up:

```bash
cmake --preset linux-gcc-static-release -DVCPKG_VERBOSE=ON
```

## Platform notes

- **Linux**: GCC and Clang fully supported
- **Windows**: MSVC with static or shared libraries
- **macOS**: Clang supported

## Versioning

| Type | Format | Example |
|------|--------|---------|
| SNAPSHOT | `X.Y.Z-<git-hash>-SNAPSHOT` | `0.3.2-abc1234-SNAPSHOT` |
| RELEASE | `X.Y.Z-RELEASE` | `0.3.2-RELEASE` |

## License

See [LICENSE](LICENSE).
