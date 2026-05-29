cmake_minimum_required(VERSION 3.25)
project(i18n-redis VERSION 0.3.2 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(I18N_REDIS_BUILD_EXAMPLES "Build example applications" OFF)
option(I18N_REDIS_BUILD_TESTS    "Build test suite"            OFF)
option(I18N_REDIS_ENABLE_LTO     "Enable link-time optimisation for Release" ON)
option(I18N_REDIS_ENABLE_ASAN    "Enable AddressSanitizer"    OFF)
option(I18N_REDIS_ENABLE_UBSAN   "Enable UndefinedBehaviourSanitizer" OFF)

find_package(Git QUIET)
if(Git_FOUND)
  execute_process(
    COMMAND ${GIT_EXECUTABLE} submodule update --init --remote --merge
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    RESULT_VARIABLE _submodule_result
    OUTPUT_QUIET
    ERROR_QUIET)
  if(NOT _submodule_result EQUAL 0)
    message(STATUS "git submodule update failed (non-git environment or no network); continuing.")
  endif()
endif()

include(CTest)

include(${CMAKE_CURRENT_LIST_DIR}/scripts/cmake/Dependencies.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/scripts/cmake/Targets.cmake)
