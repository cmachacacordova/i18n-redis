#include <iostream>

#ifndef I18N_REDIS_EXPORT_H
#ifdef _WIN32
#ifndef i18n_redis_EXPORTS
#define i18n_redis_EXPORTS
#endif
#endif
#endif

#include "i18n/i18n_redis.h"

namespace i18n::redis {

void store_message(const std::string &key) {
  nlohmann::json j = {{"message", "Hello from JSON"}};
  try {
    sw::redis::Redis redis("tcp://127.0.0.1:6379");
    redis.set(key, j.dump());
    auto val = redis.get(key);
    if (val) {
      std::cout << "Redis value: " << *val << std::endl;
    }
  } catch (const std::exception &e) { std::cerr << "Redis error: " << e.what() << std::endl; }
}

} // namespace i18n::redis
