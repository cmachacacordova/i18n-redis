# i18n-redis

A modern C++20 library for internationalisation (i18n) backed by Redis.
It loads JSON translation files from disk and stores them in Redis, then
provides fast key-based lookups with optional `{fmt}` format arguments.

Dependencies are managed via [vcpkg](https://github.com/microsoft/vcpkg).

## Requirements

| Tool | Minimum version |
|------|----------------|
| CMake | 3.25 |
| C++ compiler | C++20 (GCC 11+, Clang 13+, MSVC 2022) |
| Ninja | any recent version |
| Git | for vcpkg bootstrap |

## Dependencies

| Library | vcpkg name | Purpose |
|---------|-----------|---------|
| [redis-plus-plus](https://github.com/sewenew/redis-plus-plus) | `redis-plus-plus` | Redis client |
| [nlohmann/json](https://github.com/nlohmann/json) | `nlohmann-json` | JSON parsing |
| [{fmt}](https://github.com/fmtlib/fmt) | `fmt` | String formatting |
| [Catch2](https://github.com/catchorg/Catch2) *(optional)* | `catch2` | Test framework |

## Quick start

### 1 — Bootstrap vcpkg

```bash
# Linux / macOS
./scripts/install_vcpkg.sh

# Windows (cmd)
scripts\install_vcpkg.bat
```

This clones vcpkg into `external/vcpkg/` and builds the bootstrap binary.
No `VCPKG_ROOT` environment variable is required — the presets point directly
to `external/vcpkg/scripts/buildsystems/vcpkg.cmake`.

### 2 — Configure and build

Pick a preset that matches your platform, compiler, library type, and build
configuration:

```bash
cmake --preset linux-gcc-static-release
cmake --build out/linux-gcc-static-release
```

Or use the convenience script:

```bash
# Linux
./scripts/build_project.sh static release   # linux-gcc-static-release
./scripts/build_project.sh shared debug     # linux-gcc-shared-debug

# Windows
scripts\build_project.bat static release
```

## CMake Presets

Preset names follow the pattern `<platform>-<compiler>-<type>-<config>`.

### Linux (GCC)

| Preset | Type | Config |
|--------|------|--------|
| `linux-gcc-static-debug` | static | Debug |
| `linux-gcc-static-release` | static | Release |
| `linux-gcc-shared-debug` | shared | Debug |
| `linux-gcc-shared-release` | shared | Release |

### Linux (Clang)

| Preset | Type | Config |
|--------|------|--------|
| `linux-clang-static-debug` | static | Debug |
| `linux-clang-static-release` | static | Release |
| `linux-clang-shared-debug` | shared | Debug |
| `linux-clang-shared-release` | shared | Release |

### Windows (MSVC)

| Preset | Type | Config |
|--------|------|--------|
| `windows-msvc-static-debug` | static | Debug |
| `windows-msvc-static-release` | static | Release |
| `windows-msvc-shared-debug` | shared | Debug |
| `windows-msvc-shared-release` | shared | Release |

### macOS (Clang)

| Preset | Type | Config |
|--------|------|--------|
| `macos-clang-static-debug` | static | Debug |
| `macos-clang-static-release` | static | Release |
| `macos-clang-shared-debug` | shared | Debug |
| `macos-clang-shared-release` | shared | Release |

### Sanitizer presets

| Preset | Sanitizer |
|--------|-----------|
| `linux-clang-static-asan` | AddressSanitizer |
| `linux-clang-static-ubsan` | UndefinedBehaviourSanitizer |
| `linux-gcc-static-asan` | AddressSanitizer |
| `linux-gcc-static-ubsan` | UndefinedBehaviourSanitizer |

### LTO presets

| Preset | Notes |
|--------|-------|
| `linux-clang-static-release-lto` | Release + IPO/LTO |
| `linux-gcc-static-release-lto` | Release + IPO/LTO |

## Build options

These CMake cache variables can be passed via `-D` or configured inside your
own preset:

| Variable | Default | Description |
|----------|---------|-------------|
| `BUILD_SHARED_LIBS` | `OFF` | Build shared library instead of static |
| `I18N_REDIS_BUILD_EXAMPLES` | `ON` | Build the example application |
| `I18N_REDIS_BUILD_TESTS` | `ON` | Build the test suite |
| `I18N_REDIS_ENABLE_LTO` | `ON` | Enable IPO/LTO for Release configs |
| `I18N_REDIS_ENABLE_ASAN` | `OFF` | Enable AddressSanitizer |
| `I18N_REDIS_ENABLE_UBSAN` | `OFF` | Enable UndefinedBehaviourSanitizer |

## API usage

```cpp
#include "i18n/redis/translation_provider.h"
#include "i18n/translation.h"

// Create provider pointing to a running Redis instance
auto provider = std::make_unique<i18n::RedisTranslationProvider>("localhost", 6379);
i18n::Translation t(std::move(provider), "en");

// Load all locale JSON files from <cwd>/locales/<locale>/*.json into Redis
t.store(std::filesystem::current_path().string(), {"en", "es"});

// Simple lookup — returns the key unchanged if not found
std::string msg = t.translate("greeting");           // uses default locale "en"
std::string msg2 = t.translate("greeting", "es");   // explicit locale

// Formatted lookup with {fmt} arguments
std::string msg3 = t.translate("welcome", "en", "Alice");  // "Hello, Alice!"
```

### Translation JSON format

Each locale directory (`locales/<locale>/`) may contain any number of `.json`
files. Each file must be a JSON array of translation objects:

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

Redis keys are stored as `i18n:<locale>:<id>` (e.g. `i18n:en:greeting`).

## Downstream integration (CMake)

After installing with `cmake --install`:

```cmake
find_package(i18n-redis CONFIG REQUIRED)
target_link_libraries(my-app PRIVATE i18n-redis::i18n-redis)
```

The package config file automatically locates the transitive dependencies
(`redis++`, `nlohmann_json`, `fmt`).

### Static linking example

```bash
cmake --preset linux-gcc-static-release
cmake --build out/linux-gcc-static-release
cmake --install out/linux-gcc-static-release --prefix /opt/i18n-redis
```

### Shared linking example

```bash
cmake --preset linux-gcc-shared-release
cmake --build out/linux-gcc-shared-release
cmake --install out/linux-gcc-shared-release --prefix /opt/i18n-redis
```

## Running tests

```bash
cmake --preset linux-gcc-static-debug
cmake --build out/linux-gcc-static-debug
ctest --test-dir out/linux-gcc-static-debug --output-on-failure
```

To enable the Catch2 test framework install the `tests` vcpkg feature first:

```bash
external/vcpkg/vcpkg install --triplet x64-linux "[tests]"
cmake --preset linux-gcc-static-debug
cmake --build out/linux-gcc-static-debug
ctest --test-dir out/linux-gcc-static-debug --output-on-failure
```

## Project structure

```
i18n-redis/
├── CMakeLists.txt          # Root build definition
├── CMakePresets.json       # All build presets
├── vcpkg.json              # vcpkg manifest
├── include/
│   └── i18n/
│       ├── configuration.h        # Export macro + key format
│       ├── json.h                 # nlohmann::json alias
│       ├── translation.h          # Public Translation class
│       ├── translation_provider.h # Abstract provider interface
│       ├── types.h                # Translation struct
│       └── redis/
│           ├── connection.h            # Redis connection wrapper
│           └── translation_provider.h  # Redis-backed provider
├── src/
│   ├── connection.cpp
│   ├── redis_translation_provider.cpp
│   ├── translation.cpp
│   └── translation_provider.cpp
├── tests/
│   ├── CMakeLists.txt
│   ├── main.cpp
│   ├── test_translation_key.cpp
│   └── test_types.cpp
├── example/
│   └── main.cpp
├── locales/
│   └── en/
│       └── messages.json
├── cmake/
│   └── i18n-redisConfig.cmake.in
└── scripts/
    ├── cmake/
    │   ├── Dependencies.cmake
    │   └── Targets.cmake
    ├── build_project.sh
    ├── build_project.bat
    ├── install_vcpkg.sh
    └── install_vcpkg.bat
```

## Platform notes

- **Linux**: GCC and Clang are both fully supported. Static and shared variants
  use the `x64-linux` vcpkg triplet.
- **Windows**: MSVC (`cl`) with the `x64-windows-static-md` (static) or
  `x64-windows` (shared) triplets. The presets use Ninja as the generator.
- **macOS**: Clang with `x64-osx` / `x64-osx-dynamic` triplets. Requires Xcode
  Command Line Tools.

## CI

GitHub Actions builds are defined in `.github/workflows/ci.yml` and cover:

- Linux / GCC — static + shared, Debug + Release
- Linux / Clang — static + shared, Debug + Release
- Linux / Clang — ASan + UBSan
- Windows / MSVC — static + shared, Debug + Release

## License

See [LICENSE](LICENSE).
