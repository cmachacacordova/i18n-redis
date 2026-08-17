# Find dependencies - works with system-installed libraries or vcpkg
# For system installation, ensure libraries are in CMAKE_PREFIX_PATH or standard paths

# Redis++
find_package(redis++ CONFIG REQUIRED)
if (TARGET redis++::redis++_static)
    set(I18N_REDIS_REDIS_TARGET redis++::redis++_static)
elseif (TARGET redis++::redis++)
    set(I18N_REDIS_REDIS_TARGET redis++::redis++)
else()
    message(FATAL_ERROR "redis-plus-plus target not found")
endif()

# fmt library
find_package(fmt CONFIG REQUIRED)
if (TARGET fmt::fmt)
    set(I18N_REDIS_FMT_TARGET fmt::fmt)
elseif (TARGET fmt::fmt-header-only)
    set(I18N_REDIS_FMT_TARGET fmt::fmt-header-only)
else()
    message(FATAL_ERROR "fmt target not found")
endif()

set(I18N_REDIS_DEPENDENCIES
    ${I18N_REDIS_REDIS_TARGET}
    ${I18N_REDIS_FMT_TARGET}
)

# JSON backend validation
if (NOT I18N_REDIS_JSON_BACKEND STREQUAL "simdjson" AND NOT I18N_REDIS_JSON_BACKEND STREQUAL "yyjson")
    message(FATAL_ERROR "I18N_REDIS_JSON_BACKEND must be 'simdjson' or 'yyjson', got '${I18N_REDIS_JSON_BACKEND}'")
endif ()

# JSON backend
if (I18N_REDIS_JSON_BACKEND STREQUAL "simdjson")
    message(STATUS "Using json backend simdjson")
    find_package(simdjson CONFIG REQUIRED)
    if (TARGET simdjson::simdjson)
        list(APPEND I18N_REDIS_DEPENDENCIES simdjson::simdjson)
        message(STATUS "Using json backend simdjson - done")
    else()
        message(FATAL_ERROR "simdjson target not found")
    endif()
elseif (I18N_REDIS_JSON_BACKEND STREQUAL "yyjson")
    message(STATUS "Using json backend yyjson")
    find_package(yyjson CONFIG REQUIRED)
    if (TARGET yyjson::yyjson)
        list(APPEND I18N_REDIS_DEPENDENCIES yyjson::yyjson)
        message(STATUS "Using json backend yyjson - done")
    else()
        message(FATAL_ERROR "yyjson target not found")
    endif()
endif ()
