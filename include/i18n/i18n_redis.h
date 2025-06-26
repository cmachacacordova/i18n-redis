#pragma once

#include "i18n_redis_export.h"

#include <string>

#include <nlohmann/json.hpp>
#include <sw/redis++/redis++.h>

#include "i18n/redis/connection.h"

namespace i18n::redis {

I18N_REDIS_EXPORT void store_message(const std::string &key);

}
