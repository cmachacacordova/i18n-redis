vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL "https://github.com/cmachacacordova/i18n-redis.git"
    REF 66916ee881db958853973c63326ec13bb69a0273 # tag v0.3.0
    SHA512 7de8b4b6e24f1cff179a890173ff20b0418ae163518226cae21663a0654504496041ae4e01c607ed823ad69132a50f7c049030d51aeaff0804358c44b64c7cce
)
vcpkg_cmake_configure(SOURCE_PATH ${SOURCE_PATH})
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/i18n-redis)
file(INSTALL ${SOURCE_PATH}/README.md DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)

