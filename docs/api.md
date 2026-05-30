# i18n-redis API Reference

## `class Translation`  *(i18n/translation.h)*

High-level facade. Owns a `TranslationProvider` and exposes all public lookups.
Calls `load()` on the provider via friend access — callers only interact with
`store()` and `translate()`.

### Constructor

```cpp
Translation(std::unique_ptr<TranslationProvider> provider, std::string locale);
```

`locale` is the BCP-47 tag used as fallback when `translate()` receives an
empty locale string.

### Methods

```cpp
bool store(const std::string& cwd, const std::vector<std::string>& locales);
```

Delegates to `TranslationProvider::load()`. Returns `false` if the provider is
null, `true` if loading was attempted. Propagates `std::runtime_error` on
parsing errors.

```cpp
std::string translate(const std::string& key,
                      const std::string& locale = "") const;
```

Returns the raw translated string for `key`. Uses the default locale when
`locale` is empty. Returns `key` unchanged if no translation is found.

```cpp
template <typename... Args>
std::string translate(const std::string& key,
                      const std::string& locale,
                      Args&&... args) const;
```

Same as above but formats the result through `fmt::vformat` with `args`.
The translation string may contain `{fmt}` placeholders (e.g. `{}`).

### Example

```cpp
#include "i18n/redis/translation_provider.h"
#include "i18n/translation.h"

i18n::Translation t(
    std::make_unique<i18n::RedisTranslationProvider>("localhost", 6379), "en");

t.store("/app", {"en", "es"});

std::string s  = t.translate("greeting");           // default locale
std::string s2 = t.translate("greeting", "es");     // explicit locale
std::string s3 = t.translate("welcome", "en", "Alice"); // fmt formatting
```

---

## `class RedisTranslationProvider`  *(i18n/redis/translation_provider.h)*

Concrete `TranslationProvider` backed by Redis via `redis-plus-plus`.
Inherits from `i18n::TranslationProvider`.

`load()` is `protected` and called exclusively by `i18n::Translation` through
friend access.

### Constructor

```cpp
explicit RedisTranslationProvider(const std::string& host, int port);
```

Throws `std::runtime_error` if the connection cannot be established.

### Public methods

```cpp
std::string get(const std::string& key, const std::string& locale) const override;
```

Queries Redis for the key `i18n:<locale>:<key>`, parses the stored JSON with
the active backend, and returns the `value` field as plain text. Returns `key`
unchanged if the entry is not found or the JSON is malformed.

### Protected methods

```cpp
bool load(const std::string& cwd,
          const std::vector<std::string>& locales) override;
```

Scans `<cwd>/locales/<locale>/*.json` for each requested locale, validates
every entry (all six fields required: `id`, `value`, `category`,
`creationDate`, `modificationDate`, `modificationVersion`; `id` must not
contain `:`), and stores the raw JSON object in Redis under
`i18n:<locale>:<id>`. Returns `true` if all locales were processed. Throws
`std::runtime_error` on missing fields or invalid `id`.

### Private members

```cpp
std::unique_ptr<sw::redis::Redis> m_redis;
```

---

## `class TranslationProvider`  *(i18n/translation_provider.h)*

Abstract base class. Implement this to provide a custom backend.

```cpp
class TranslationProvider {
public:
  TranslationProvider();

  virtual std::string get(const std::string& key,
                          const std::string& locale = "en") const = 0;

  virtual bool load(const std::string& cwd,
                    const std::vector<std::string>& locales) = 0;

  virtual ~TranslationProvider() noexcept;
};
```

`get()` must return the translated string or `key` unchanged if not found.
`load()` must return `true` when all locales were processed, and may throw
`std::runtime_error` on errors.

---

## `configuration.h`  *(i18n/configuration.h)*

```cpp
namespace i18n {
  inline constexpr std::string_view kFormatKey = "i18n:{}:{}";
}
```

`kFormatKey` is the `{fmt}` format string used to build Redis keys.
Arguments: `locale`, `id`. Example result: `i18n:en:greeting`.

---

## Locale file format

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

All six fields are required. `id` must not contain `:`.

---

## JSON backend

Selected per CMake preset. Both `VCPKG_MANIFEST_FEATURES` and
`I18N_REDIS_JSON_BACKEND` are set automatically — no manual `-D` flags needed.

| Preset suffix | Backend | vcpkg feature | CMake define |
|---------------|---------|---------------|--------------|
| *(none)* | simdjson | `simdjson` | `I18N_REDIS_USE_SIMDJSON` |
| `-yyjson` | yyjson | `yyjson` | `I18N_REDIS_USE_YYJSON` |

```bash
# simdjson — use any preset without suffix
cmake --preset linux-gcc-static-release
cmake --build --preset linux-gcc-static-release

# yyjson — use any preset with -yyjson suffix
cmake --preset linux-gcc-static-release-yyjson
cmake --build --preset linux-gcc-static-release-yyjson
```

The hidden presets `backend-simdjson` and `backend-yyjson` defined in
`CMakePresets.json` can be inherited in a downstream `CMakeUserPresets.json`.

### Convenience script

`build_project.sh` / `build_project.bat` select the correct preset automatically:

```bash
./scripts/build_project.sh static release gcc simdjson
./scripts/build_project.sh static release gcc yyjson
```

If `VCPKG_HOME` is unset, the script initialises the `extras/vcpkg` submodule
and bootstraps vcpkg before running cmake.

---

## CMake integration

```cmake
find_package(i18n-redis CONFIG REQUIRED)
target_link_libraries(my-app PRIVATE i18n-redis::i18n-redis)
```

Transitive dependencies (`redis++`, `fmt`, and the JSON backend) are resolved
automatically by the package config.

---

## Export macro

`I18N_REDIS_EXPORT` is generated by `GenerateExportHeader`. It expands to the
correct visibility attribute for shared builds and to nothing for static builds.

Define `I18N_REDIS_STATIC_DEFINE` when linking against a static install.
