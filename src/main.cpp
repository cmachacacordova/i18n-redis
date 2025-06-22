#include <sw/redis++/redis++.h>
#include <nlohmann/json.hpp>
#include <iostream>

int main() {
    nlohmann::json j = {{"message", "Hello from JSON"}};

    try {
        auto redis = sw::redis::Redis("tcp://127.0.0.1:6379");
        redis.set("sample_key", j.dump());
        auto val = redis.get("sample_key");
        if (val) {
            std::cout << "Redis value: " << *val << std::endl;
        }
    } catch (const std::exception &e) {
        std::cerr << "Redis error: " << e.what() << std::endl;
    }
    return 0;
}
