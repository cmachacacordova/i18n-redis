cmake_minimum_required(VERSION 3.25)
project(i18n-redis VERSION 1.3.4 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(I18N_REDIS_BUILD_EXAMPLES "Build example applications"                OFF)
option(I18N_REDIS_BUILD_TESTS    "Build test suite"                          OFF)
option(I18N_REDIS_ENABLE_LTO     "Enable link-time optimisation for Release" ON)
option(I18N_REDIS_ENABLE_ASAN    "Enable AddressSanitizer"                   OFF)
option(I18N_REDIS_ENABLE_UBSAN   "Enable UndefinedBehaviourSanitizer"        OFF)

set(I18N_REDIS_JSON_BACKEND "simdjson" CACHE STRING "JSON backend to use for parsing locale files (simdjson | yyjson)")
set_property(CACHE I18N_REDIS_JSON_BACKEND PROPERTY STRINGS simdjson yyjson)

include(CTest)

include(${CMAKE_CURRENT_LIST_DIR}/cmake/Modules/Dependencies.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/cmake/Modules/Targets.cmake)
