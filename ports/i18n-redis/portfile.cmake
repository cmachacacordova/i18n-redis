vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO owner/i18n-redis
    REF 766e57764dafc6f233e7a331850dd70f8db58ed1
    SHA512 e268ac21677f731ba445875522c8d7a780c4a72cf149cca552def82cf6a4b78535bd7cff5c8d4c8d3152563d8f9dbaf213076ec9ecaa1e62ecd483459bcc87e0
    HEAD_REF main
)

vcpkg_cmake_configure(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
)

vcpkg_cmake_install()

vcpkg_cmake_config_fixup()

file(INSTALL ${SOURCE_PATH}/README.md DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT})
