# i18n-redis

A C++20 library for internationalisation (i18n) backed by Redis. Loads JSON
locale files from disk, stores each entry in Redis, and provides fast
key-based lookups with optional `{fmt}` format arguments.

**Version:** `{VERSION}`  
**Build Type:** `{BUILD_TYPE}`  
**Release Date:** `{RELEASE_DATE}`

---

## Quick Start

### Requirements

| Tool | Minimum Version |
|------|-----------------|
| CMake | 3.25 |
| C++ Compiler | C++20 (GCC 11+, Clang 13+, MSVC 2022) |
| Ninja | any recent |
| Redis Server | 5.0+ |

### Install Dependencies

**Ubuntu / Debian:**
```bash
sudo apt-get install -y cmake ninja-build g++ \
  libhiredis-dev libredis++-dev libfmt-dev \
  libyyjson-dev libsimdjson-dev
```

**Fedora / RHEL:**
```bash
sudo dnf install cmake ninja-build gcc-c++ \
  hiredis-devel redis-plus-plus-devel fmt-devel \
  yyjson-devel simdjson-devel
```

**Arch Linux:**
```bash
sudo pacman -S cmake ninja gcc hiredis fmt yyjson simdjson
# From AUR: yay -S redis-plus-plus
```

**macOS (Homebrew):**
```bash
brew install cmake ninja hiredis redis-plus-plus fmt yyjson simdjson
```

**Windows (vcpkg):**
```powershell
vcpkg install redis-plus-plus fmt simdjson hiredis
# For yyjson: vcpkg install redis-plus-plus fmt yyjson hiredis
```

### Build & Install

**Linux / macOS:**
```bash
tar -xzf i18n-redis-{VERSION}.tar.gz
cd i18n-redis-{VERSION}

./configure -p linux-gcc-static-release
cmake --install out/build --prefix /usr/local
```

**Windows:**
```powershell
Expand-Archive i18n-redis-{VERSION}.zip
cd i18n-redis-{VERSION}

.\configure.ps1 -Preset windows-msvc-static-release
cmake --install out\build --prefix "C:\Program Files\i18n-redis"
```

### CMake Integration

```cmake
find_package(i18n-redis CONFIG REQUIRED)
target_link_libraries(my-app PRIVATE i18n-redis::i18n-redis)
```

---

## Usage

```cpp
#include "i18n/redis/RedisTranslationProvider.h"
#include "i18n/Translation.h"

// Create provider
auto provider = std::make_unique<i18n::RedisTranslationProvider>("localhost", 6379);
i18n::Translation t(std::move(provider), "en");

// Load locale files into Redis
t.store(std::filesystem::current_path().string(), {"en", "es"});

// Translate
std::string msg = t.translate("greeting");              // "Hello!"
std::string msg2 = t.translate("greeting", "es");        // "¡Hola!"
std::string msg3 = t.translate("welcome", "en", "Alice"); // "Welcome, Alice!"
```

### Locale File Format

Place JSON files in `locales/<locale>/`:

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

---

## Build Options

### Release Presets (Production)

| Preset | Platform | Compiler | Linkage |
|--------|----------|----------|---------|
| `linux-gcc-static-release` | Linux | GCC | static |
| `linux-clang-static-release` | Linux | Clang | static |
| `windows-msvc-static-release` | Windows | MSVC | static |
| `macos-clang-static-release` | macOS | Clang | static |

### Debug Presets (Development)

| Preset | Platform | Compiler | Linkage |
|--------|----------|----------|---------|
| `linux-gcc-static-debug` | Linux | GCC | static |
| `linux-clang-static-debug` | Linux | Clang | static |
| `windows-msvc-static-debug` | Windows | MSVC | static |
| `macos-clang-static-debug` | macOS | Clang | static |

### JSON Backend

Presets without suffix use **simdjson**. Add `-yyjson` suffix for **yyjson**:

```bash
# simdjson (base preset)
./configure -p linux-gcc-static-release

# yyjson (add suffix)
./configure -p linux-gcc-static-release-yyjson
```

### Other Build Types

| Preset | Platform | Type |
|--------|----------|------|
| `linux-gcc-shared-release` | Linux | Shared library |
| `linux-clang-shared-release` | Linux | Shared library |
| `linux-clang-static-asan` | Linux | AddressSanitizer |
| `linux-gcc-static-release-lto` | Linux | Release + LTO |

---

## Dependencies

| Library | Purpose | Required Version |
|---------|---------|------------------|
| redis-plus-plus | Redis client | >= 1.3.0 |
| {fmt} | String formatting | >= 9.0 |
| simdjson | JSON parsing | >= 3.0 |
| yyjson | JSON parsing | >= 0.8 |
| hiredis | Redis C client | >= 1.0 |

---

## Troubleshooting

### CMake Cannot Find Dependencies

Verify packages are installed:
```bash
# Ubuntu/Debian
dpkg -l | grep -E "hiredis|fmt|yyjson|simdjson"

# Fedora/RHEL
rpm -qa | grep -E "hiredis|fmt|yyjson|simdjson"
```

For non-standard paths:
```bash
cmake --preset linux-gcc-static-release \
  -DCMAKE_PREFIX_PATH="/custom/path/to/libs"
```

### Redis Connection Issues

Verify Redis is running:
```bash
redis-cli ping  # Should return PONG
```

---

## Resources

- **Repository:** https://github.com/cmachaca/i18n-redis
- **Documentation:** https://github.com/cmachaca/i18n-redis/blob/main/docs/api.md
- **Issue Tracker:** https://github.com/cmachaca/i18n-redis/issues
- **Releases:** https://github.com/cmachaca/i18n-redis/releases

## License

See [LICENSE](LICENSE) file for details.

---

*This package was generated automatically.*  
*For development instructions, see the full README.md in the repository.*
