vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL "https://github.com/cmachacacordova/i18n-redis.git"
    REF ee91ffb4ad42c1aad6e668494a4071023c2b39d7 # tag v0.2.0
    SHA512 c09f205d87495ebe007ecb637a7c101b9bb1540c37d2f924a7f171c86847c553e64bbe7b557949942a4846839cdd3e7a0eb601be6786a9f51bb2209a78bad108
)
vcpkg_cmake_configure(SOURCE_PATH ${SOURCE_PATH})
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/i18n-redis)
file(INSTALL ${SOURCE_PATH}/README.md DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
