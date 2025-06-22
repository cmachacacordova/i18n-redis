#include "i18n_redis.h"
#include <iostream>

namespace i18n_redis {

void store_message(const std::string& key) {
    nlohmann::json j = {{"message", "Hello from JSON"}};
    try {
        sw::redis::Redis redis("tcp://127.0.0.1:6379");
        redis.set(key, j.dump());
        auto val = redis.get(key);
        if (val) {
            std::cout << "Redis value: " << *val << std::endl;
        }
    } catch (const std::exception& e) {
        std::cerr << "Redis error: " << e.what() << std::endl;
    }
}

}
