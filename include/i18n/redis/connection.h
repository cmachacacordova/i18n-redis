#pragma once

#include "i18n_redis_export.h"

#include <memory>
#include <optional>
#include <stdexcept>
#include <string>

#include <sw/redis++/redis++.h>

#include "i18n/json.h"

namespace i18n::redis {

/// @brief RAII wrapper around a redis++ connection pool.
///
/// Provides typed read/write helpers on top of a @c sw::redis::Redis
/// instance. All I/O is synchronous and exceptions from the underlying
/// library are propagated as @c std::runtime_error.
///
/// The class is move-only (copy is explicitly deleted).
class I18N_REDIS_EXPORT Connection {

private:
  std::unique_ptr<sw::redis::Redis> m_redis; ///< Underlying redis++ client.

public:
  /// @brief Connects to a Redis server and initialises the connection pool.
  /// @param host Hostname or IP address of the Redis server.
  /// @param port TCP port of the Redis server (default: 6379).
  /// @throws std::runtime_error if the connection cannot be established.
  explicit Connection(const std::string &host, int port = 6379);

  Connection(const Connection &) = delete;
  Connection(Connection &&) noexcept = default;

  Connection &operator=(const Connection &) = delete;
  Connection &operator=(Connection &&) noexcept = default;

  /// @brief Reads and deserialises a value from Redis.
  ///
  /// The generic overload retrieves the raw string, parses it as JSON,
  /// and then calls @c nlohmann::json::get<T>().
  /// Specialisations for @c std::string and @c i18n::json short-circuit
  /// the JSON step when the target type already matches the wire format.
  ///
  /// @tparam T   Destination type; must be JSON-deserialisable.
  /// @param key  Redis key to look up.
  /// @return The deserialised value, or @c std::nullopt if the key is absent.
  template <typename T>
  std::optional<T> value(const std::string &key) const;

  /// @brief Serialises and writes a value to Redis.
  ///
  /// The generic overload converts @p val to JSON and delegates to the
  /// @c i18n::json specialisation. Specialisations for @c std::string
  /// and @c i18n::json are provided for direct storage without extra conversion.
  ///
  /// @tparam T   Source type; must be JSON-serialisable.
  /// @param key  Redis key to write.
  /// @param val  Value to store.
  /// @return The value that was stored.
  /// @throws std::invalid_argument if the serialised representation is empty.
  template <typename T>
  T store(const std::string &key, const T &val) const;

  ~Connection() noexcept;
};

template <>
inline std::optional<std::string> Connection::value<std::string>(const std::string &key) const {
  auto val = m_redis->get(key);
  if (val) {
    return *val;
  }
  return std::nullopt;
}

template <>
inline std::optional<i18n::json> Connection::value<i18n::json>(const std::string &key) const {
  if (auto val = this->value<std::string>(key)) {
    return std::make_optional<i18n::json>(i18n::json::parse(*val));
  }
  return std::nullopt;
}

template <typename T>
std::optional<T> Connection::value(const std::string &key) const {
  if (std::optional<i18n::json> val = this->value<i18n::json>(key)) {
    return std::make_optional<T>(val->template get<T>());
  }
  return std::nullopt;
}

template <>
inline std::string Connection::store<std::string>(const std::string &key, const std::string &val) const {
  if (val.empty()) {
    throw std::invalid_argument("Value cannot be empty");
  }
  m_redis->set(key, val);
  return val;
}

template <>
inline i18n::json Connection::store<i18n::json>(const std::string &key, const i18n::json &val) const {
  const auto str = val.dump();
  if (str.empty()) {
    throw std::invalid_argument("JSON value cannot be empty");
  }
  this->store<std::string>(key, str);
  return val;
}

template <typename T>
T Connection::store(const std::string &key, const T &val) const {
  this->store<i18n::json>(key, i18n::json(val));
  return val;
}

} // namespace i18n::redis
