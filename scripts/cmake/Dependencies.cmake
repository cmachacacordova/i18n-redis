# Locate third-party packages and save dependency list
find_package(nlohmann_json CONFIG REQUIRED)
find_package(redis++ CONFIG REQUIRED)
find_package(fmt CONFIG REQUIRED)

# Dependencies used across build targets
set(I18N_REDIS_DEPENDENCIES
    $<IF:$<TARGET_EXISTS:redis++::redis++_static>,redis++::redis++_static,redis++::redis++>
    nlohmann_json::nlohmann_json
    fmt::fmt-header-only
)
