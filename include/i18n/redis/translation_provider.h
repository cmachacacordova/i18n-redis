#pragma once

#include "i18n_redis_export.h"

#include "i18n/translation_provider.h"

#include <sw/redis++/redis++.h>

namespace i18n {

class I18N_REDIS_EXPORT Translation;

/// @brief Redis-backed implementation of @c TranslationProvider.
///
/// Reads JSON locale files from disk (via @c load()) and stores each entry
/// as a raw JSON object in Redis under the key pattern defined by
/// @c i18n::kFormatKey. @c get() retrieves the JSON, parses the @c value
/// field, and returns it as plain text.
///
/// @c load() is protected; @c i18n::Translation calls it via friend access.
class I18N_REDIS_EXPORT RedisTranslationProvider : public TranslationProvider {
public:
  /// @brief Connects to a Redis server.
  /// @param host Hostname or IP address.
  /// @param port TCP port.
  explicit RedisTranslationProvider(const std::string &host, int port);

  /// @brief Retrieves the translated string for a key from Redis.
  /// @param key    Translation identifier (no colons).
  /// @param locale BCP-47 locale tag (e.g. "en").
  /// @return The @c value field of the stored entry, or @p key if not found.
  std::string get(const std::string &key, const std::string &locale) const override;

  ~RedisTranslationProvider() noexcept override;

protected:
  /// @brief Parses locale JSON files and stores each entry in Redis.
  /// @param cwd     Directory containing the "locales/<locale>/" folder tree.
  /// @param locales List of locale tags to process.
  /// @throws std::runtime_error if a required field is missing or @c id contains @c :.
  bool load(const std::string &cwd, const std::vector<std::string> &locales) override;

private:
  std::unique_ptr<sw::redis::Redis> m_redis; ///< Underlying redis++ client.
  friend class i18n::Translation;
};

} // namespace i18n
