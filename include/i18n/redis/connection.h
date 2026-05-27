#pragma once

#include "i18n/configuration.h"

#include <memory>
#include <optional>
#include <stdexcept>
#include <string>

#include <sw/redis++/redis++.h>

#include "i18n/json.h"

namespace i18n::redis {
class I18N_REDIS_EXPORT Connection {

private:
  std::unique_ptr<sw::redis::Redis> redis_;

public:
  explicit Connection(const std::string &host, int port = 6379);

  Connection(const Connection &) = delete;
  Connection &operator=(const Connection &) = delete;
  Connection(Connection &&) noexcept = default;
  Connection &operator=(Connection &&) noexcept = default;

  template <typename T>
  std::optional<T> value(const std::string &key) const {
    if (std::optional<i18n::json> val = this->value<i18n::json>(key)) {
      return std::make_optional<T>(val->template get<T>());
    }
    return std::nullopt;
  }

  template <typename T>
  T store(const std::string &key, const T &val) const {
    this->store<i18n::json>(key, i18n::json(val));
    return val;
  }

  ~Connection() noexcept;
};

template <>
inline std::optional<std::string> Connection::value<std::string>(const std::string &key) const {
  auto val = redis_->get(key);
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

template <>
inline std::string Connection::store<std::string>(const std::string &key, const std::string &val) const {
  if (val.empty()) {
    throw std::invalid_argument("Value cannot be empty");
  }
  redis_->set(key, val);
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

} // namespace i18n::redis
