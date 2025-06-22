#pragma once
#include "i18n_redis_export.h"
#include <sw/redis++/redis++.h>
#include <nlohmann/json.hpp>
#include <string>

namespace i18n_redis {

I18N_REDIS_EXPORT void store_message(const std::string& key);

}
