#pragma once

#include "i18n_redis_export.h"

#include "i18n/TranslationProvider.h"

#include "sw/redis++/redis++.h"

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
  /// @brief Creates a Redis connection pool.
  /// @param host Hostname or IP address.
  /// @param port TCP port.
  /// @throws std::runtime_error if the connection cannot be established.
  explicit RedisTranslationProvider(const std::string &host, int port);

  /// @brief Queries Redis for "i18n:<locale>:<key>" and extracts the value field.
  /// @param key    Translation identifier (no colons allowed).
  /// @param locale BCP-47 locale tag (e.g. "en").
  /// @return The @c value field from the stored JSON, or @p key if not found/malformed.
  std::string get(const std::string &key, const std::string &locale) const override;

  ~RedisTranslationProvider() noexcept override;

protected:
  /// @brief Parses locale JSON files and stores each entry in Redis.
  /// @param cwd     Directory containing the "locales/<locale>/" folder tree.
  /// @param locales List of locale tags to process.
  /// @return @c true if all requested locales exist and were processed.
  /// @throws std::runtime_error if a required field is missing or @c id contains @c :.
  bool load(const std::string &cwd, const std::vector<std::string> &locales) override;

private:
  std::unique_ptr<sw::redis::Redis> m_redis; ///< Underlying redis++ client.
  friend class i18n::Translation;
};

} // namespace i18n
