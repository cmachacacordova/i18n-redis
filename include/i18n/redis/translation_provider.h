#pragma once

#include "i18n_redis_export.h"

#include "i18n/redis/connection.h"
#include "i18n/translation_provider.h"

namespace i18n {

class I18N_REDIS_EXPORT Translation;

/// @brief Redis-backed implementation of @c TranslationProvider.
///
/// Reads JSON locale files from disk (via @c load()) and stores each
/// @c TranslationRegister entry in Redis under the key pattern
/// defined by @c I18N_FORMAT_KEY. Subsequent calls to @c get()
/// retrieve and deserialise those entries directly from Redis.
///
/// Only @c i18n::Translation is allowed to call @c load() (friend).
class I18N_REDIS_EXPORT RedisTranslationProvider : public TranslationProvider {
private:
  i18n::redis::Connection m_connection; ///< Connection to the Redis server.

  /// @brief Reads locale JSON files and writes entries into Redis.
  /// @param cwd     Directory containing the "locales/<locale>/" folder tree.
  /// @param locales List of locale tags to process.
  /// @return @c false if @p locales is empty; @c true otherwise.
  /// @throws std::runtime_error on JSON parse errors or invalid entry fields.
  bool load(const std::string &cwd, const std::vector<std::string> &locales) const override;

public:
  /// @brief Connects to a Redis server.
  /// @param host Hostname or IP address.
  /// @param port TCP port.
  RedisTranslationProvider(const std::string &host, int port);

  /// @brief Looks up a translation from Redis.
  /// @param key    Translation identifier.
  /// @param locale BCP-47 locale tag.
  /// @return The translated string, or @p key if no entry is found in Redis.
  std::string get(const std::string &key, const std::string &locale) const override;

  ~RedisTranslationProvider() override;

  friend class i18n::Translation;
};

} // namespace i18n
