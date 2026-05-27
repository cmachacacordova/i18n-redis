find_package(nlohmann_json CONFIG REQUIRED)
find_package(redis++ CONFIG REQUIRED)
find_package(fmt CONFIG REQUIRED)

set(I18N_REDIS_REDIS_TARGET
    $<IF:$<TARGET_EXISTS:redis++::redis++_static>,redis++::redis++_static,redis++::redis++>)

set(I18N_REDIS_DEPENDENCIES
    ${I18N_REDIS_REDIS_TARGET}
    nlohmann_json::nlohmann_json
    fmt::fmt-header-only
)
