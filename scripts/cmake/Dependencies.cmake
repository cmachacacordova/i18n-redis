# Locate third-party packages and set up interface target
find_package(nlohmann_json CONFIG REQUIRED)
find_package(redis++ CONFIG REQUIRED)

add_library(i18n-redis-deps INTERFACE)
target_link_libraries(i18n-redis-deps INTERFACE
    $<IF:$<TARGET_EXISTS:redis++::redis++_static>,redis++::redis++_static,redis++::redis++>
    nlohmann_json::nlohmann_json
)
