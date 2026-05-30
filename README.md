# i18n-redis

A C++20 library for internationalisation (i18n) backed by Redis. Loads JSON
locale files from disk, stores each entry in Redis, and provides fast
key-based lookups with optional `{fmt}` format arguments.

## Requirements

| Tool | Minimum version |
|------|----------------|
| CMake | 3.25 |
| C++ compiler | C++20 (GCC 11+, Clang 13+, MSVC 2022) |
| Ninja | any recent |

## Dependencies

| Library | Purpose |
|---------|---------|
| [redis-plus-plus](https://github.com/sewenew/redis-plus-plus) | Redis client |
| [{fmt}](https://github.com/fmtlib/fmt) | String formatting |
| [simdjson](https://github.com/simdjson/simdjson) *(default)* | JSON parsing |
| [yyjson](https://github.com/ibireme/yyjson) *(alternative)* | JSON parsing |
| [Catch2](https://github.com/catchorg/Catch2) *(tests only)* | Test framework |

## Building

### 1 — Set `VCPKG_HOME`

All presets resolve the vcpkg toolchain through the `VCPKG_HOME` environment
variable. Set it to the root of a bootstrapped vcpkg installation before
running any `cmake` command.

```bash
export VCPKG_HOME=/path/to/vcpkg
```

### 2 — Configure and build

```bash
cmake --preset linux-gcc-static-release
cmake --build --preset linux-gcc-static-release
```

Or use the convenience script:

```bash
./scripts/build_project.sh static release
./scripts/build_project.sh shared debug
```

### JSON backend

The JSON backend is selected at configure time. `simdjson` is the default.

```bash
cmake --preset linux-gcc-static-release
cmake --preset linux-gcc-static-release -DI18N_REDIS_JSON_BACKEND=yyjson -DVCPKG_MANIFEST_FEATURES=yyjson
```

## CMake Presets

Preset names follow the pattern `<platform>-<compiler>-<type>-<config>`.

### Linux

| Preset | Compiler | Type | Config |
|--------|----------|------|--------|
| `linux-gcc-static-debug` | GCC | static | Debug |
| `linux-gcc-static-release` | GCC | static | Release |
| `linux-gcc-shared-debug` | GCC | shared | Debug |
| `linux-gcc-shared-release` | GCC | shared | Release |
| `linux-clang-static-debug` | Clang | static | Debug |
| `linux-clang-static-release` | Clang | static | Release |
| `linux-clang-shared-debug` | Clang | shared | Debug |
| `linux-clang-shared-release` | Clang | shared | Release |

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

### Sanitizers / LTO

| Preset | Notes |
|--------|-------|
| `linux-clang-static-asan` | AddressSanitizer |
| `linux-clang-static-ubsan` | UndefinedBehaviourSanitizer |
| `linux-gcc-static-asan` | AddressSanitizer |
| `linux-gcc-static-ubsan` | UndefinedBehaviourSanitizer |
| `linux-clang-static-release-lto` | Release + LTO |
| `linux-gcc-static-release-lto` | Release + LTO |

## Build options

| Variable | Default | Description |
|----------|---------|-------------|
| `I18N_REDIS_JSON_BACKEND` | `simdjson` | JSON backend: `simdjson` or `yyjson` |
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

## vcpkg

The library can be installed via vcpkg. The `vcpkg.json` manifest declares
the following features:

| Feature | Description |
|---------|-------------|
| `simdjson` | Use simdjson as the JSON backend (default) |
| `yyjson` | Use yyjson as the JSON backend |
| `tests` | Build the Catch2 test suite |

## Running tests

```bash
cmake --preset linux-gcc-static-debug
cmake --build --preset linux-gcc-static-debug --clean-first
ctest --test-dir out/build --output-on-failure
```

## Project structure

```
i18n-redis/
├── CMakeLists.txt
├── CMakePresets.json
├── vcpkg.json
├── vcpkg-configuration.json
├── vcpkg/                          # git submodule: overlay ports and triplets
│   ├── ports/
│   └── triplets/
├── include/
│   └── i18n/
│       ├── configuration.h
│       ├── translation.h
│       ├── translation_provider.h
│       └── redis/
│           └── translation_provider.h
├── src/
│   ├── redis_translation_provider.cpp
│   ├── translation.cpp
│   └── translation_provider.cpp
├── tests/
│   ├── CMakeLists.txt
│   ├── main.cpp
│   └── test_translation_key.cpp
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
    └── version.sh
```

## Platform notes

- **Linux**: GCC and Clang fully supported. Uses `x64-linux` vcpkg triplet.
- **Windows**: MSVC with `x64-windows-static-md` (static) or `x64-windows` (shared).
- **macOS**: Clang with `x64-osx` / `x64-osx-dynamic`.

## Versioning

| Type | Format | Example |
|------|--------|---------|
| SNAPSHOT | `X.Y.Z-<git-hash>-SNAPSHOT` | `0.3.2-abc1234-SNAPSHOT` |
| RELEASE | `X.Y.Z-RELEASE` | `0.3.2-RELEASE` |

## License

See [LICENSE](LICENSE).
