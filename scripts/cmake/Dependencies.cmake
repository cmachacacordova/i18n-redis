# Locate third-party packages and set up interface target
find_package(nlohmann_json CONFIG REQUIRED)
find_package(redis++ CONFIG REQUIRED)

add_library(i18n-redis-deps INTERFACE)
target_link_libraries(i18n-redis-deps INTERFACE
    redis++::redis++_static
    nlohmann_json::nlohmann_json
)
