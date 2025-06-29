vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL "https://github.com/cmachacacordova/i18n-redis.git"
    REF 00a1245bffbdd8dc18246694a51808af33611826 # tag v0.2.1
    SHA512 b1996c0fec403731c672eeef8c2a88d23ed5f3caacdf61dabc7115c5cd38b14a7fabdae229e7648164b967981c0961464b4a46129ec9131c805c52029c0f3d70
)
vcpkg_cmake_configure(SOURCE_PATH ${SOURCE_PATH})
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/i18n-redis)
file(INSTALL ${SOURCE_PATH}/README.md DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
