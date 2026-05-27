#include "i18n/configuration.h"

#include <cassert>
#include <cstdlib>
#include <iostream>
#include <string>

#include <fmt/core.h>

#ifndef I18N_REDIS_NO_CATCH2
#include <catch2/catch_test_macros.hpp>

TEST_CASE("I18N_FORMAT_KEY produces expected Redis key format", "[configuration]") {
    const std::string key = fmt::format(I18N_FORMAT_KEY, "en", "greeting");
    REQUIRE(key == "i18n:en:greeting");
}

TEST_CASE("I18N_FORMAT_KEY with different locale", "[configuration]") {
    const std::string key = fmt::format(I18N_FORMAT_KEY, "es", "error");
    REQUIRE(key == "i18n:es:error");
}

#else

int runKeyTests() {
    {
        const std::string key = fmt::format(I18N_FORMAT_KEY, "en", "greeting");
        assert(key == "i18n:en:greeting");
        std::cout << "[PASS] I18N_FORMAT_KEY en:greeting\n";
    }
    {
        const std::string key = fmt::format(I18N_FORMAT_KEY, "es", "error");
        assert(key == "i18n:es:error");
        std::cout << "[PASS] I18N_FORMAT_KEY es:error\n";
    }
    return EXIT_SUCCESS;
}

#endif
