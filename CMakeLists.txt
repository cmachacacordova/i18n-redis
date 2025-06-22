cmake_minimum_required(VERSION 3.14)
project(i18n-redis LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(nlohmann_json CONFIG REQUIRED)
find_package(redis++ CONFIG REQUIRED)

add_library(i18n-redis
    src/i18n_redis.cpp
)

target_include_directories(i18n-redis PUBLIC
    ${PROJECT_SOURCE_DIR}/include
)

target_link_libraries(i18n-redis PUBLIC
    redis++
    nlohmann_json::nlohmann_json
)
