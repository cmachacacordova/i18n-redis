find_package(Catch2 3 QUIET)

if(Catch2_FOUND)
    add_executable(i18n-redis-tests
        test_translation_key.cpp
        test_types.cpp
    )
    target_link_libraries(i18n-redis-tests
        PRIVATE
            i18n-redis::i18n-redis
            Catch2::Catch2WithMain)
    target_compile_features(i18n-redis-tests PRIVATE cxx_std_20)

    include(Catch)
    catch_discover_tests(i18n-redis-tests)
else()
    message(STATUS "Catch2 not found — building lightweight tests without a framework")

    add_executable(i18n-redis-tests
        main.cpp
        test_translation_key.cpp
        test_types.cpp
    )
    target_link_libraries(i18n-redis-tests PRIVATE i18n-redis::i18n-redis)
    target_compile_features(i18n-redis-tests PRIVATE cxx_std_20)
    target_compile_definitions(i18n-redis-tests PRIVATE I18N_REDIS_NO_CATCH2)

    add_test(NAME i18n-redis-tests COMMAND i18n-redis-tests)
endif()
