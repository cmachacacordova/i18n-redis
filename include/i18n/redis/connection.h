#pragma once

#include "i18n/configuration.h"

#include <memory>
#include <optional>
#include <string>

#include <sw/redis++/redis++.h>

#include "i18n/json.h"

namespace i18n::redis {
class I18N_REDIS_EXPORT Connection {

private:
  std::unique_ptr<sw::redis::Redis> redis_;

  // Disable copy and assignment
  Connection(const Connection &) = delete;
  Connection &operator=(const Connection &) = delete;

public:
  Connection(const std::string &, int = 6379);

  template <typename T>
  std::optional<T> value(const std::string &key) const {
    if (std::optional<i18n::json> val = this->template value<i18n::json>(key)) {
      return std::make_optional<T>(val->get<T>());
    }
    return std::nullopt;
  }

  template <typename T>
  T store(const std::string &key, const T &val) const {
    this->store<i18n::json>(key, i18n::json(val));
    return val;
  }

  ~Connection();
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
    return std::make_optional<i18n::json>(json::parse(*val));
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
  auto str = val.dump();
  if (str.empty()) {
    throw std::invalid_argument("JSON value cannot be empty");
  }
  this->store<std::string>(key, str);
  return val;
}

} // namespace i18n::redis
