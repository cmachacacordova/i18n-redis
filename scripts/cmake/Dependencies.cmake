find_package(redis++ CONFIG REQUIRED)
find_package(fmt CONFIG REQUIRED)

set(I18N_REDIS_REDIS_TARGET $<IF:$<TARGET_EXISTS:redis++::redis++_static>,redis++::redis++_static,redis++::redis++>)

set(I18N_REDIS_DEPENDENCIES
    ${I18N_REDIS_REDIS_TARGET}
    fmt::fmt-header-only
)

if (NOT I18N_REDIS_JSON_BACKEND STREQUAL "simdjson" AND NOT I18N_REDIS_JSON_BACKEND STREQUAL "yyjson")
    message(FATAL_ERROR "I18N_REDIS_JSON_BACKEND must be 'simdjson' or 'yyjson', got '${I18N_REDIS_JSON_BACKEND}'")
endif ()

if (I18N_REDIS_JSON_BACKEND STREQUAL "simdjson")
    message(STATUS "i18n-redis: JSON backend = simdjson")
    find_package(simdjson CONFIG REQUIRED)
    list(APPEND I18N_REDIS_DEPENDENCIES simdjson::simdjson)
elseif (I18N_REDIS_JSON_BACKEND STREQUAL "yyjson")
    message(STATUS "i18n-redis: JSON backend = yyjson")
    find_package(yyjson CONFIG REQUIRED)
    list(APPEND I18N_REDIS_DEPENDENCIES yyjson::yyjson)
endif ()
