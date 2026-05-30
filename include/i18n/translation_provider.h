#pragma once

#include "i18n_redis_export.h"

#include <string>
#include <vector>

namespace i18n {

/// @brief Abstract base class for translation backends.
///
/// Defines the interface every translation backend must implement:
/// loading locale files into the backing store and retrieving
/// individual translated strings by key.
class I18N_REDIS_EXPORT TranslationProvider {

public:
  TranslationProvider();

  /// @brief Retrieves the translated string for a given key and locale.
  /// @param key    Translation identifier (no colons allowed).
  /// @param locale BCP-47 locale tag (default: "en").
  /// @return The translated string, or @p key unchanged if not found.
  virtual std::string get(const std::string &key, const std::string &locale = "en") const = 0;

  /// @brief Loads translation files from disk into the backing store.
  /// @param cwd     Working directory that contains the "locales/" subdirectory.
  /// @param locales List of locale tags to load (e.g. {"en", "es"}).
  /// @return @c true if all requested locales exist and were processed.
  /// @throws std::runtime_error on parsing errors or invalid translation data.
  virtual bool load(const std::string &cwd, const std::vector<std::string> &locales) = 0;

  virtual ~TranslationProvider() noexcept;
};

} // namespace i18n
