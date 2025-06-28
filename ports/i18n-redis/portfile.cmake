vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL "https://github.com/cmachacacordova/i18n-redis.git"
    REF 47fff296199ab4180d01cb76f8b99ab21fed7726
    SHA512 0161c51fee4a2b2ad639080994e0c6f4506c80e9913c64c203ead5d00372db95aa1a0bcee525ac941c02f6eb9a43fa5bdf6b579551162a44f025d5d5d2181cff
)
vcpkg_cmake_configure(SOURCE_PATH ${SOURCE_PATH})
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/i18n-redis)
file(INSTALL ${SOURCE_PATH}/README.md DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
