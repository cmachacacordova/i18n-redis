vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL "https://github.com/cmachacacordova/i18n-redis.git"
    REF be1d9a9623de827934f50bf260aab803a5f6d123 # tag v0.1.0
    SHA512 36e085c078c45c3babd9edc1b3512d4025417cc737fbc2110dd15d73e8d7141e4d713fdda9643b40b3103e292321a39383a35ceed0175b910253be6e5f81ecf4
)
vcpkg_cmake_configure(SOURCE_PATH ${SOURCE_PATH})
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/i18n-redis)
file(INSTALL ${SOURCE_PATH}/README.md DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
