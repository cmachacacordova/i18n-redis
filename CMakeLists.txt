cmake_minimum_required(VERSION 3.14)
project(i18n-redis VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable link time optimization for Release builds when available
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)

# Organise build logic into separate modules
include(${CMAKE_CURRENT_LIST_DIR}/scripts/cmake/Dependencies.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/scripts/cmake/Targets.cmake)

include(CMakePackageConfigHelpers)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/i18n-redisConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

configure_package_config_file(
    ${CMAKE_CURRENT_LIST_DIR}/cmake/i18n-redisConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/i18n-redisConfig.cmake
    INSTALL_DESTINATION lib/cmake/i18n-redis
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/i18n-redisConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/i18n-redisConfigVersion.cmake
    DESTINATION lib/cmake/i18n-redis
)
