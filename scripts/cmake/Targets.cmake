# Build options
option(I18N_REDIS_BUILD_BOTH "Build shared and static libraries" OFF)

include(GenerateExportHeader)

# Gather all cpp files under src and reconfigure when files change
file(GLOB I18N_REDIS_SOURCES CONFIGURE_DEPENDS
    ${PROJECT_SOURCE_DIR}/src/*.cpp)

# Object library compiled once
add_library(i18n-redis-obj OBJECT ${I18N_REDIS_SOURCES})
set_property(TARGET i18n-redis-obj PROPERTY POSITION_INDEPENDENT_CODE ON)
target_include_directories(i18n-redis-obj PUBLIC
    ${PROJECT_SOURCE_DIR}/include
    ${PROJECT_BINARY_DIR}
)
target_link_libraries(i18n-redis-obj PUBLIC i18n-redis-deps)

if(I18N_REDIS_BUILD_BOTH)
    add_library(i18n-redis-static STATIC $<TARGET_OBJECTS:i18n-redis-obj>)
    add_library(i18n-redis-shared SHARED $<TARGET_OBJECTS:i18n-redis-obj>)

    # Avoid name clash of .lib files on Windows
    set_target_properties(i18n-redis-static PROPERTIES OUTPUT_NAME i18n-redis_static)
    if(WIN32)
        set_target_properties(i18n-redis-shared PROPERTIES
            OUTPUT_NAME i18n-redis
            ARCHIVE_OUTPUT_NAME i18n-redis_shared)
    else()
        set_target_properties(i18n-redis-shared PROPERTIES OUTPUT_NAME i18n-redis)
    endif()

    set(i18n_redis_targets i18n-redis-static i18n-redis-shared)
    generate_export_header(i18n-redis-shared
        EXPORT_MACRO_NAME I18N_REDIS_EXPORT
        EXPORT_FILE_NAME ${PROJECT_BINARY_DIR}/i18n_redis_export.h)
else()
    if(BUILD_SHARED_LIBS)
        add_library(i18n-redis SHARED $<TARGET_OBJECTS:i18n-redis-obj>)
    else()
        add_library(i18n-redis STATIC $<TARGET_OBJECTS:i18n-redis-obj>)
    endif()
    set(i18n_redis_targets i18n-redis)
    generate_export_header(i18n-redis
        EXPORT_MACRO_NAME I18N_REDIS_EXPORT
        EXPORT_FILE_NAME ${PROJECT_BINARY_DIR}/i18n_redis_export.h)
endif()

foreach(tgt IN LISTS i18n_redis_targets)
    target_link_libraries(${tgt} PUBLIC i18n-redis-deps)
    target_include_directories(${tgt}
        PUBLIC
            $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
            $<BUILD_INTERFACE:${PROJECT_BINARY_DIR}>
            $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
    )
endforeach()

include(GNUInstallDirs)
install(TARGETS ${i18n_redis_targets} i18n-redis-deps
    EXPORT i18n-redis-targets
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})
install(DIRECTORY ${PROJECT_SOURCE_DIR}/include/
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

# Example application to test the library
add_executable(i18n-redis-example example/main.cpp)
if(TARGET i18n-redis)
    target_link_libraries(i18n-redis-example PRIVATE i18n-redis)
elseif(TARGET i18n-redis-static)
    target_link_libraries(i18n-redis-example PRIVATE i18n-redis-static)
else()
    target_link_libraries(i18n-redis-example PRIVATE i18n-redis-shared)
endif()
