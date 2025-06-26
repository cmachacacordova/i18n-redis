include(vcpkg-cmake)
include(vcpkg-cmake-config-fixup)

vcpkg_cmake_configure(
    SOURCE_PATH ${CMAKE_CURRENT_LIST_DIR}/../../
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/i18n-redis)

file(REMOVE_RECURSE ${CURRENT_PACKAGES_DIR}/debug ${CURRENT_PACKAGES_DIR}/lib/cmake)
