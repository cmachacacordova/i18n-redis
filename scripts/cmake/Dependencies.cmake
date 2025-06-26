# Locate third-party packages and set up interface target
find_package(nlohmann_json CONFIG REQUIRED)
find_package(redis++ CONFIG REQUIRED)

# When using static triplets, the redis++ port installs the target
# `redis++::redis++_static` instead of `redis++::redis++`. Provide an alias so
# the rest of the project can use a consistent name regardless of linkage.
if(TARGET redis++::redis++_static AND NOT TARGET redis++::redis++)
    add_library(redis++::redis++ ALIAS redis++::redis++_static)
endif()

add_library(i18n-redis-deps INTERFACE)
target_link_libraries(i18n-redis-deps INTERFACE
    redis++::redis++
    nlohmann_json::nlohmann_json
)
