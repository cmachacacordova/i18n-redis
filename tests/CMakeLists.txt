find_package(Catch2 3 QUIET)

if(MSVC)
    set(_test_warnings /W4 /WX /permissive-)
elseif(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    set(_test_warnings -Wall -Wextra -Wpedantic -Werror -Wno-unknown-warning-option)
else()
    set(_test_warnings -Wall -Wextra -Wpedantic -Werror)
endif()

if(Catch2_FOUND)
    add_executable(i18n-redis-tests
        TestTranslationKey.cpp
    )
    target_link_libraries(i18n-redis-tests
        PRIVATE
            i18n-redis::i18n-redis
            Catch2::Catch2WithMain)
    target_compile_features(i18n-redis-tests PRIVATE cxx_std_20)
    target_compile_options(i18n-redis-tests PRIVATE ${_test_warnings})

    include(Catch)
    catch_discover_tests(i18n-redis-tests)
else()
    message(STATUS "Catch2 not found — building lightweight tests without a framework")

    add_executable(i18n-redis-tests
        Main.cpp
        TestTranslationKey.cpp
    )
    target_link_libraries(i18n-redis-tests PRIVATE i18n-redis::i18n-redis)
    target_compile_features(i18n-redis-tests PRIVATE cxx_std_20)
    target_compile_definitions(i18n-redis-tests PRIVATE I18N_REDIS_NO_CATCH2)
    target_compile_options(i18n-redis-tests PRIVATE ${_test_warnings})

    add_test(NAME i18n-redis-tests COMMAND i18n-redis-tests)
endif()
