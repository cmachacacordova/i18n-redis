cmake_minimum_required(VERSION 3.14)
project(i18n-redis LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable link time optimization for Release builds when available
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)

find_package(nlohmann_json CONFIG REQUIRED)
find_package(redis++ CONFIG REQUIRED)

# Use the static target name when present (vcpkg names it
# `redis++_static` when built with a static triplet).
if(TARGET redis++_static AND NOT TARGET redis++)
    add_library(redis++ ALIAS redis++_static)
endif()

# Dependencies used by both library types
add_library(i18n-redis-deps INTERFACE)
target_link_libraries(i18n-redis-deps INTERFACE
    redis++
    nlohmann_json::nlohmann_json
)

# Compile sources once and reuse in static and shared variants
add_library(i18n-redis-obj OBJECT src/i18n_redis.cpp)
set_property(TARGET i18n-redis-obj PROPERTY POSITION_INDEPENDENT_CODE ON)
target_include_directories(i18n-redis-obj PUBLIC ${PROJECT_SOURCE_DIR}/include)
target_link_libraries(i18n-redis-obj PUBLIC i18n-redis-deps)

add_library(i18n-redis-static STATIC $<TARGET_OBJECTS:i18n-redis-obj>)
add_library(i18n-redis-shared SHARED $<TARGET_OBJECTS:i18n-redis-obj>)
set_target_properties(i18n-redis-static PROPERTIES OUTPUT_NAME i18n-redis)
set_target_properties(i18n-redis-shared PROPERTIES OUTPUT_NAME i18n-redis)

foreach(tgt i18n-redis-static i18n-redis-shared)
    target_link_libraries(${tgt} PUBLIC i18n-redis-deps)
    target_include_directories(${tgt} PUBLIC ${PROJECT_SOURCE_DIR}/include)
endforeach()
