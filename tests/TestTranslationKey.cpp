#include "i18n/Configuration.h"

#include <cassert>
#include <cstdlib>
#include <iostream>
#include <string>

#include <fmt/core.h>

#ifndef I18N_REDIS_NO_CATCH2
#include <catch2/catch_test_macros.hpp>

TEST_CASE("kFormatKey produces expected Redis key format", "[configuration]") {
  const std::string key = fmt::format(i18n::kFormatKey, "en", "greeting");
  REQUIRE(key == "i18n:en:greeting");
}

TEST_CASE("kFormatKey with different locale", "[configuration]") {
  const std::string key = fmt::format(i18n::kFormatKey, "es", "error");
  REQUIRE(key == "i18n:es:error");
}

TEST_CASE("kFormatKey with different key", "[configuration]") {
  const std::string key = fmt::format(i18n::kFormatKey, "fr", "welcome");
  REQUIRE(key == "i18n:fr:welcome");
}

#else

int runKeyTests() {
  {
    const std::string key = fmt::format(i18n::kFormatKey, "en", "greeting");
    assert(key == "i18n:en:greeting");
    std::cout << "[PASS] kFormatKey en:greeting\n";
  }
  {
    const std::string key = fmt::format(i18n::kFormatKey, "es", "error");
    assert(key == "i18n:es:error");
    std::cout << "[PASS] kFormatKey es:error\n";
  }
  {
    const std::string key = fmt::format(i18n::kFormatKey, "fr", "welcome");
    assert(key == "i18n:fr:welcome");
    std::cout << "[PASS] kFormatKey fr:welcome\n";
  }
  return EXIT_SUCCESS;
}

#endif
