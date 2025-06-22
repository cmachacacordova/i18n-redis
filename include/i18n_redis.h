#pragma once
#include <sw/redis++/redis++.h>
#include <nlohmann/json.hpp>
#include <string>

namespace i18n_redis {

void store_message(const std::string& key);

}
