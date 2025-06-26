#pragma once

#include "i18n_redis_export.h"

#include <memory>
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
  T value(const std::string &key) {
    return this->value<i18n::json>(key).template get<T>();
  }

  template <typename T>
  T store(const std::string &key, const T &val) {
    this->store<i18n::json>(key, i18n::json(val));
    return val;
  }

  ~Connection();
};

template <>
inline std::string Connection::value<std::string>(const std::string &key) {
  auto val = redis_->get(key);
  if (val) {
    return *val;
  }
  return "";
}

template <>
inline i18n::json Connection::value<i18n::json>(const std::string &key) {
  auto val = this->value<std::string>(key);
  if (val.empty()) {
    return json::object();
  }
  return json::parse(val);
}

template <>
inline std::string Connection::store<std::string>(const std::string &key, const std::string &val) {
  if (val.empty()) {
    throw std::invalid_argument("Value cannot be empty");
  }
  redis_->set(key, val);
  return val;
}

template <>
inline i18n::json Connection::store<i18n::json>(const std::string &key, const i18n::json &val) {
  auto str = val.dump();
  if (str.empty()) {
    throw std::invalid_argument("JSON value cannot be empty");
  }
  this->store<std::string>(key, str);
  return val;
}

} // namespace i18n::redis
