cmake_minimum_required(VERSION 3.14)
project(i18n-redis LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)

FetchContent_Declare(
    nlohmann_json
    GIT_REPOSITORY https://github.com/nlohmann/json.git
    GIT_TAG v3.11.2
)
FetchContent_MakeAvailable(nlohmann_json)

FetchContent_Declare(
    hiredis
    GIT_REPOSITORY https://github.com/redis/hiredis.git
    GIT_TAG v1.0.2
)
FetchContent_MakeAvailable(hiredis)

FetchContent_Declare(
    redis_plus_plus
    GIT_REPOSITORY https://github.com/sewenew/redis-plus-plus.git
    GIT_TAG 1.3.9
)
set(REDIS_PLUS_PLUS_CXX_STANDARD 17 CACHE STRING "" FORCE)
set(REDIS_PLUS_PLUS_BUILD_TEST OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(redis_plus_plus)

add_library(i18n-redis
    src/i18n_redis.cpp
)

target_include_directories(i18n-redis PUBLIC
    ${PROJECT_SOURCE_DIR}/include
)

add_library(redis++::redis++ ALIAS redis++)
add_library(hiredis::hiredis ALIAS hiredis)

target_link_libraries(i18n-redis PUBLIC
    hiredis::hiredis
    redis++::redis++
    nlohmann_json::nlohmann_json
)
