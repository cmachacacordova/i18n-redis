include(GenerateExportHeader)
include(GNUInstallDirs)
include(CheckIPOSupported)

# ── Compiler warning flags (target-based, not global) ──────────────────────
set(I18N_REDIS_MSVC_WARNINGS /W4 /WX /permissive- /wd4251)
set(I18N_REDIS_GNU_WARNINGS
    -Wall -Wextra -Wpedantic -Werror
    -Wshadow -Wnon-virtual-dtor -Wold-style-cast
    -Wcast-align -Woverloaded-virtual -Wconversion
    -Wsign-conversion -Wnull-dereference -Wdouble-promotion
    -Wformat=2 -Wimplicit-fallthrough)
set(I18N_REDIS_CLANG_WARNINGS ${I18N_REDIS_GNU_WARNINGS} -Wno-unknown-warning-option)

# ── Sanitizer flags ──────────────────────────────────────────────────────────
set(I18N_REDIS_SANITIZER_FLAGS "")
if(I18N_REDIS_ENABLE_ASAN)
    list(APPEND I18N_REDIS_SANITIZER_FLAGS -fsanitize=address -fno-omit-frame-pointer)
endif()
if(I18N_REDIS_ENABLE_UBSAN)
    list(APPEND I18N_REDIS_SANITIZER_FLAGS -fsanitize=undefined)
endif()

# ── Source files ─────────────────────────────────────────────────────────────
file(GLOB I18N_REDIS_SOURCES CONFIGURE_DEPENDS ${PROJECT_SOURCE_DIR}/src/*.cpp)

# ── Object library (compiled once, shared between static/shared targets) ─────
add_library(i18n-redis-obj OBJECT ${I18N_REDIS_SOURCES})
set_target_properties(i18n-redis-obj PROPERTIES POSITION_INDEPENDENT_CODE ON)

target_compile_definitions(i18n-redis-obj PRIVATE i18n_redis_EXPORTS)
target_include_directories(i18n-redis-obj
    PUBLIC
        $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
        $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}>
    PRIVATE
        ${PROJECT_SOURCE_DIR}/src)
target_link_libraries(i18n-redis-obj PRIVATE ${I18N_REDIS_DEPENDENCIES})

if(MSVC)
    target_compile_options(i18n-redis-obj PRIVATE ${I18N_REDIS_MSVC_WARNINGS})
elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    target_compile_options(i18n-redis-obj PRIVATE ${I18N_REDIS_CLANG_WARNINGS} ${I18N_REDIS_SANITIZER_FLAGS})
    target_link_options(i18n-redis-obj INTERFACE ${I18N_REDIS_SANITIZER_FLAGS})
else()
    target_compile_options(i18n-redis-obj PRIVATE ${I18N_REDIS_GNU_WARNINGS} ${I18N_REDIS_SANITIZER_FLAGS})
    target_link_options(i18n-redis-obj INTERFACE ${I18N_REDIS_SANITIZER_FLAGS})
endif()

if (I18N_REDIS_JSON_BACKEND STREQUAL "simdjson")
    target_compile_definitions(i18n-redis-obj PRIVATE I18N_REDIS_USE_SIMDJSON)
    if (NOT MSVC)
        target_compile_options(i18n-redis-obj PRIVATE -march=native)
    endif ()
elseif (I18N_REDIS_JSON_BACKEND STREQUAL "yyjson")
    target_compile_definitions(i18n-redis-obj PRIVATE I18N_REDIS_USE_YYJSON YYJSON_DISABLE_NON_STANDARD)
endif ()

# ── Main library target ───────────────────────────────────────────────────────
if(BUILD_SHARED_LIBS)
    add_library(i18n-redis SHARED $<TARGET_OBJECTS:i18n-redis-obj>)
else()
    add_library(i18n-redis STATIC $<TARGET_OBJECTS:i18n-redis-obj>)
endif()
add_library(i18n-redis::i18n-redis ALIAS i18n-redis)

generate_export_header(i18n-redis
    BASE_NAME i18n_redis
    EXPORT_MACRO_NAME I18N_REDIS_EXPORT
    EXPORT_FILE_NAME ${PROJECT_BINARY_DIR}/i18n_redis_export.h
    STATIC_DEFINE I18N_REDIS_STATIC_DEFINE)

target_include_directories(i18n-redis
    PUBLIC
        $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
        $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}>
        $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
target_link_libraries(i18n-redis PUBLIC ${I18N_REDIS_DEPENDENCIES})
if(I18N_REDIS_SANITIZER_FLAGS)
  target_link_options(i18n-redis PRIVATE ${I18N_REDIS_SANITIZER_FLAGS})
endif()

# ── LTO (opt-in, Release configs only) ───────────────────────────────────────
if(I18N_REDIS_ENABLE_LTO)
    check_ipo_supported(RESULT _ipo_supported OUTPUT _ipo_output)
    if(_ipo_supported)
        set_target_properties(i18n-redis PROPERTIES
            INTERPROCEDURAL_OPTIMIZATION_RELEASE         ON
            INTERPROCEDURAL_OPTIMIZATION_RELWITHDEBINFO  ON
            INTERPROCEDURAL_OPTIMIZATION_MINSIZEREL      ON)
    else()
        message(STATUS "IPO/LTO not supported: ${_ipo_output}")
    endif()
endif()

# ── Install & export ──────────────────────────────────────────────────────────
install(TARGETS i18n-redis
    EXPORT i18n-redis-targets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(FILES ${PROJECT_BINARY_DIR}/i18n_redis_export.h
    DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(EXPORT i18n-redis-targets
    NAMESPACE i18n-redis::
    FILE i18n-redisTargets.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/i18n-redis)

include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    ${PROJECT_BINARY_DIR}/i18n-redisConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion)
configure_package_config_file(
    ${PROJECT_SOURCE_DIR}/cmake/i18n-redisConfig.cmake.in
    ${PROJECT_BINARY_DIR}/i18n-redisConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/i18n-redis)
install(FILES
    ${PROJECT_BINARY_DIR}/i18n-redisConfig.cmake
    ${PROJECT_BINARY_DIR}/i18n-redisConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/i18n-redis)

# ── Example ───────────────────────────────────────────────────────────────────
if(I18N_REDIS_BUILD_EXAMPLES)
    add_executable(i18n-redis-example ${PROJECT_SOURCE_DIR}/example/main.cpp)
    target_link_libraries(i18n-redis-example PRIVATE i18n-redis::i18n-redis)
endif()

# ── Tests ─────────────────────────────────────────────────────────────────────
if(I18N_REDIS_BUILD_TESTS AND BUILD_TESTING)
    add_subdirectory(${PROJECT_SOURCE_DIR}/tests)
endif()
