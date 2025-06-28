cmake_minimum_required(VERSION 3.14)
project(i18n-redis VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable link time optimization for Release builds when available
set(CMAKE_INTERPROCEDURAL_OPTIMIZATION_RELEASE ON)

# Organise build logic into separate modules
include(${CMAKE_CURRENT_LIST_DIR}/scripts/cmake/Dependencies.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/scripts/cmake/Targets.cmake)
