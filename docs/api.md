# i18n-redis API Reference

Complete reference for the i18n-redis C++ library.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Quick Start](#quick-start)
- [Class Reference](#class-reference)
  - [Translation](#class-translation)
  - [TranslationProvider](#class-translationprovider)
  - [RedisTranslationProvider](#class-redistranslationprovider)
- [Configuration](#configuration)
- [Locale File Format](#locale-file-format)
- [JSON Backends](#json-backends)
- [CMake Integration](#cmake-integration)
- [Error Handling](#error-handling)
- [Performance Notes](#performance-notes)

---

## Overview

i18n-redis is a C++20 internationalization library that stores translations in Redis for fast, distributed access. The library uses a three-layer architecture:

1. **Translation** — High-level facade for application code
2. **TranslationProvider** — Abstract interface for storage backends
3. **RedisTranslationProvider** — Concrete Redis implementation

### Key Features

- JSON locale files loaded from disk to Redis
- Fast key-based lookups with sub-millisecond latency
- `{fmt}` integration for parameterized translations
- Pluggable architecture (custom backends via `TranslationProvider`)
- Two JSON parsers: simdjson (default) and yyjson

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                    Your Application                  │
└────────────────────────┬─────────────────────────────┘
                         │
                         ▼
┌──────────────────────────────────────────────────────┐
│                  class Translation                   │
│  ┌────────────────────────────────────────────────┐  │
│  │  store()  →  loads JSON files into Redis       │  │
│  │  translate() →  retrieves and formats strings  │  │
│  └────────────────────────────────────────────────┘  │
└────────────────────────┬─────────────────────────────┘
                         │ owns
                         ▼
┌──────────────────────────────────────────────────────┐
│           class TranslationProvider (abstract)       │
│                    interface                         │
│  ┌────────────────────────────────────────────────┐  │
│  │  get(key, locale) →  fetch from storage        │  │
│  │  load(cwd, locales) →  populate storage        │  │
│  └────────────────────────────────────────────────┘  │
└────────────────────────┬─────────────────────────────┘
                         │ implements
                         ▼
┌──────────────────────────────────────────────────────┐
│        class RedisTranslationProvider                │
│  ┌────────────────────────────────────────────────┐  │
│  │  Redis connection via redis-plus-plus          │  │
│  │  JSON parsing (simdjson/yyjson)                │  │
│  └────────────────────────────────────────────────┘  │
└────────────────────────┬─────────────────────────────┘
                         │
                         ▼
                   ┌──────────┐
                   │  Redis   │
                   └──────────┘
```

---

## Quick Start

### Basic Usage

```cpp
#include "i18n/redis/RedisTranslationProvider.h"
#include "i18n/Translation.h"

// 1. Create provider with Redis connection
auto provider = std::make_unique<i18n::RedisTranslationProvider>("localhost", 6379);

// 2. Create Translation facade with default locale
i18n::Translation t(std::move(provider), "en");

// 3. Load locale files from disk to Redis
t.store("/app/locales", {"en", "es", "fr"});

// 4. Translate
std::string greeting = t.translate("greeting");           // "Hello!"
std::string greek = t.translate("greeting", "es");          // "¡Hola!"
std::string welcome = t.translate("welcome", "en", "Alice"); // "Welcome, Alice!"
```

### Translation with Parameters

Locale file:
```json
{
  "id": "welcome",
  "value": "Welcome, {0}! You have {1} messages."
}
```

Code:
```cpp
std::string msg = t.translate("welcome", "en", "Alice", 5);
// Result: "Welcome, Alice! You have 5 messages."
```

---

## Class Reference

### Class: `Translation`

**Header:** `i18n/Translation.h`

The main interface for your application. Owns a `TranslationProvider` and provides all public translation methods.

#### Constructor

```cpp
Translation(std::unique_ptr<TranslationProvider> provider,
            std::string locale);
```

| Parameter | Description |
|-----------|-------------|
| `provider` | Unique pointer to a `TranslationProvider` implementation (e.g., `RedisTranslationProvider`) |
| `locale` | Default BCP-47 locale tag (e.g., `"en"`, `"es-ES"`, `"zh-Hans"`) |

**Example:**
```cpp
auto redis = std::make_unique<i18n::RedisTranslationProvider>("localhost", 6379);
i18n::Translation t(std::move(redis), "en");
```

---

#### Method: `store()`

```cpp
bool store(const std::string& cwd,
           const std::vector<std::string>& locales);
```

Loads JSON locale files from disk and stores them in Redis.

| Parameter | Description |
|-----------|-------------|
| `cwd` | Base directory containing `locales/` subdirectory |
| `locales` | List of locale tags to load (e.g., `{"en", "es"}`) |

**Returns:** `true` if processing was attempted (actual load delegated to provider)

**Throws:** `std::runtime_error` on file parsing errors

**File Layout:**
```
/app/locales/
├── en/
│   ├── messages.json
│   └── errors.json
├── es/
│   └── messages.json
└── fr/
    └── messages.json
```

**Example:**
```cpp
t.store("/app", {"en", "es", "fr"});
```

---

#### Method: `translate()` (simple)

```cpp
std::string translate(const std::string& key,
                      const std::string& locale = "") const;
```

Retrieves a translation by key.

| Parameter | Description |
|-----------|-------------|
| `key` | Translation identifier (e.g., `"greeting"`) |
| `locale` | Target locale (empty = use default locale from constructor) |

**Returns:** Translated string, or `key` unchanged if not found

**Example:**
```cpp
std::string msg = t.translate("greeting");       // uses default "en"
std::string msg = t.translate("greeting", "es"); // explicit locale
```

---

#### Method: `translate()` (with formatting)

```cpp
template <typename... Args>
std::string translate(const std::string& key,
                      const std::string& locale,
                      Args&&... args) const;
```

Retrieves and formats a translation using `{fmt}` syntax.

| Parameter | Description |
|-----------|-------------|
| `key` | Translation identifier |
| `locale` | Target locale (cannot be defaulted here) |
| `args` | Format arguments for `{fmt}` placeholders |

**Returns:** Formatted translated string

**Example:**
```cpp
// Locale file: { "value": "Hello, {0}! You have {1} new messages." }
std::string msg = t.translate("welcome", "en", "Alice", 5);
// Result: "Hello, Alice! You have 5 new messages."
```

---

### Class: `TranslationProvider`

**Header:** `i18n/TranslationProvider.h`

Abstract base class for implementing custom storage backends. Inherit from this to create providers for databases other than Redis.

#### Interface

```cpp
class TranslationProvider {
public:
    virtual ~TranslationProvider() noexcept = default;

    // Fetch translation from storage
    virtual std::string get(const std::string& key,
                            const std::string& locale) const = 0;

    // Load translations into storage
    virtual bool load(const std::string& cwd,
                      const std::vector<std::string>& locales) = 0;
};
```

#### Implementing a Custom Provider

```cpp
class FileTranslationProvider : public i18n::TranslationProvider {
public:
    std::string get(const std::string& key,
                    const std::string& locale) const override {
        // Read from local map or file
        return translations_.at(locale + ":" + key);
    }

    bool load(const std::string& cwd,
              const std::vector<std::string>& locales) override {
        // Load files into memory
        return true;
    }

private:
    std::unordered_map<std::string, std::string> translations_;
};
```

---

### Class: `RedisTranslationProvider`

**Header:** `i18n/redis/RedisTranslationProvider.h`

Concrete implementation of `TranslationProvider` using Redis as the storage backend.

#### Constructor

```cpp
explicit RedisTranslationProvider(const std::string& host, int port);
```

| Parameter | Description |
|-----------|-------------|
| `host` | Redis server hostname or IP address |
| `port` | Redis server port (typically 6379) |

**Throws:** `std::runtime_error` if connection fails

**Example:**
```cpp
auto provider = std::make_unique<i18n::RedisTranslationProvider>(
    "redis.example.com", 6380);
```

---

#### Redis Key Format

Keys are stored as: `i18n:{locale}:{id}`

| Key | Value (JSON) |
|-----|--------------|
| `i18n:en:greeting` | `{ "id": "greeting", "value": "Hello!", ... }` |
| `i18n:es:greeting` | `{ "id": "greeting", "value": "¡Hola!", ... }` |

---

## Configuration

### Key Format String

**Header:** `i18n/Configuration.h`

```cpp
namespace i18n {
    inline constexpr std::string_view kFormatKey = "i18n:{}:{}";
}
```

The `{fmt}` format string used to construct Redis keys.
- Argument 1: locale (e.g., `"en"`)
- Argument 2: translation id (e.g., `"greeting"`)
- Result: `i18n:en:greeting`

---

## Locale File Format

Each locale directory (`locales/<locale>/`) contains `.json` files with translation entries.

### File Structure

```json
[
  {
    "id": "greeting",
    "value": "Hello, {0}!",
    "category": "General",
    "creationDate": "2024-01-01",
    "modificationDate": "2024-06-01",
    "modificationVersion": 1
  },
  {
    "id": "farewell",
    "value": "Goodbye, {0}!",
    "category": "General",
    "creationDate": "2024-01-01",
    "modificationDate": "2024-06-01",
    "modificationVersion": 2
  }
]
```

### Field Requirements

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `id` | string | Unique identifier | Required, cannot contain `:` |
| `value` | string | Translated text | Required, supports `{fmt}` placeholders |
| `category` | string | Logical grouping | Required |
| `creationDate` | string | ISO 8601 date | Required |
| `modificationDate` | string | ISO 8601 date | Required |
| `modificationVersion` | integer | Version counter | Required, increments on changes |

### Directory Layout

```
project/
├── src/
├── locales/
│   ├── en/
│   │   ├── common.json
│   │   ├── errors.json
│   │   └── validation.json
│   ├── es/
│   │   ├── common.json
│   │   └── errors.json
│   └── fr/
│       └── common.json
└── CMakeLists.txt
```

---

## JSON Backends

The library supports two JSON parsing backends selected at compile time.

### Backend Selection

| Backend | Speed | Memory | Best For |
|---------|-------|--------|----------|
| **simdjson** (default) | Fastest | Minimal | Production, high throughput |
| **yyjson** | Fast | Low | Compatibility, embedded systems |

### CMake Configuration

Select via preset (recommended):

```bash
# simdjson (default)
cmake --preset linux-gcc-static-release
cmake --build --preset linux-gcc-static-release

# yyjson
cmake --preset linux-gcc-static-release-yyjson
cmake --build --preset linux-gcc-static-release-yyjson
```

Or manually:
```bash
cmake -DI18N_REDIS_JSON_BACKEND=simdjson ...
cmake -DI18N_REDIS_JSON_BACKEND=yyjson ...
```

### Preset Suffix Reference

| Suffix | Backend | CMake Define |
|--------|---------|--------------|
| (none) | simdjson | `I18N_REDIS_USE_SIMDJSON` |
| `-yyjson` | yyjson | `I18N_REDIS_USE_YYJSON` |

---

## CMake Integration

### Finding the Package

```cmake
find_package(i18n-redis CONFIG REQUIRED)

# Link to your target
target_link_libraries(my-app PRIVATE i18n-redis::i18n-redis)
```

### Transitive Dependencies

The following are automatically resolved:
- `redis++` (Redis client)
- `fmt` (formatting library)
- JSON backend (simdjson or yyjson)

### Static Linking

When linking statically, define:
```cmake
target_compile_definitions(my-app PRIVATE I18N_REDIS_STATIC_DEFINE)
```

### Export Macro

`I18N_REDIS_EXPORT` is generated by `GenerateExportHeader`. It expands to:
- Platform-specific visibility attributes for shared builds
- Empty for static builds

---

## Error Handling

### Exception Hierarchy

```
std::runtime_error
├── Connection errors (Redis unavailable)
├── Parse errors (invalid JSON)
└── Validation errors (missing fields, invalid id)
```

### Common Error Scenarios

| Scenario | Exception | Solution |
|----------|-----------|----------|
| Redis unreachable | `std::runtime_error` | Check connection, retry with backoff |
| Invalid JSON | `std::runtime_error` | Validate locale files with schema |
| Missing field | `std::runtime_error` | Ensure all 6 required fields present |
| Key not found | (none) | Returns key unchanged — check key spelling |

### Defensive Programming

```cpp
try {
    auto provider = std::make_unique<i18n::RedisTranslationProvider>(host, port);
    i18n::Translation t(std::move(provider), "en");

    if (!t.store(cwd, locales)) {
        // Handle store failure
    }
} catch (const std::runtime_error& e) {
    // Log and potentially fallback to default strings
    std::cerr << "i18n initialization failed: " << e.what() << "\n";
}
```

---

## Performance Notes

### Redis Operations

| Operation | Complexity | Typical Latency |
|-----------|------------|-----------------|
| `get()` | O(1) | < 1ms (local Redis) |
| `load()` | O(N) | Depends on file size |

### Optimization Tips

1. **Connection pooling**: `RedisTranslationProvider` maintains one persistent connection
2. **Pipeline loads**: The `load()` method uses Redis pipelines for batch insertion
3. **Lazy loading**: Consider loading locales only when first accessed
4. **JSON backend**: Use simdjson for maximum throughput

### Benchmark Reference

| Backend | Parse 1MB JSON | Relative |
|---------|----------------|----------|
| simdjson | ~2ms | 1.0× (baseline) |
| yyjson | ~4ms | 2.0× |

---

## Complete Example

```cpp
#include "i18n/redis/RedisTranslationProvider.h"
#include "i18n/Translation.h"
#include <iostream>

int main() {
    try {
        // Initialize
        auto provider = std::make_unique<i18n::RedisTranslationProvider>(
            "localhost", 6379);
        i18n::Translation t(std::move(provider), "en");

        // Load translations
        t.store("/app/locales", {"en", "es", "fr"});

        // Simple translations
        std::cout << t.translate("greeting") << "\n";
        std::cout << t.translate("greeting", "es") << "\n";

        // Parameterized translations
        std::cout << t.translate("welcome", "en", "Alice", 5) << "\n";
        std::cout << t.translate("welcome", "es", "María", 3) << "\n";

    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << "\n";
        return 1;
    }

    return 0;
}
```

Compile:
```bash
g++ -std=c++20 example.cpp -li18n-redis -lfmt -lredis++ -lhiredis
```
