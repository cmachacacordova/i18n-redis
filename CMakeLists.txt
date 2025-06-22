cmake_minimum_required(VERSION 3.14)
project(i18n-redis LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable link time optimization for Release builds when available
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)

find_package(nlohmann_json CONFIG REQUIRED)
find_package(redis++ CONFIG REQUIRED)

option(I18N_REDIS_BUILD_BOTH "Build shared and static libraries" OFF)

if(I18N_REDIS_BUILD_BOTH)
    add_library(i18n-redis-static STATIC src/i18n_redis.cpp)
    add_library(i18n-redis-shared SHARED src/i18n_redis.cpp)

    set(common_targets i18n-redis-static i18n-redis-shared)
else()
    add_library(i18n-redis src/i18n_redis.cpp)
    set(common_targets i18n-redis)
endif()

foreach(tgt IN LISTS common_targets)
    target_include_directories(${tgt} PUBLIC
        ${PROJECT_SOURCE_DIR}/include
    )

    target_link_libraries(${tgt} PUBLIC
        redis++
        nlohmann_json::nlohmann_json
    )
endforeach()
