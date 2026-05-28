#include "i18n/types.h"

#include <cassert>
#include <cstdlib>
#include <iostream>
#include <string>

#ifndef I18N_REDIS_NO_CATCH2
#include <catch2/catch_test_macros.hpp>

TEST_CASE("Translation struct default initialisation", "[types]") {
  i18n::TranslationRegister t;
  REQUIRE(t.id.empty());
  REQUIRE(t.value.empty());
  REQUIRE(t.category.empty());
  REQUIRE(t.creationDate.empty());
  REQUIRE(t.modificationDate.empty());
  REQUIRE(t.modificationVersion == 0);
}

TEST_CASE("Translation struct field assignment", "[types]") {
  i18n::TranslationRegister t;
  t.id = "key";
  t.value = "Hello";
  t.category = "General";
  t.creationDate = "2024-01-01";
  t.modificationDate = "2024-06-01";
  t.modificationVersion = 2;

  REQUIRE(t.id == "key");
  REQUIRE(t.value == "Hello");
  REQUIRE(t.category == "General");
  REQUIRE(t.modificationVersion == 2);
}

#else

int runTests() {
  {
    i18n::TranslationRegister t;
    assert(t.id.empty());
    assert(t.value.empty());
    assert(t.category.empty());
    assert(t.creationDate.empty());
    assert(t.modificationDate.empty());
    assert(t.modificationVersion == 0);
    std::cout << "[PASS] Translation default initialisation\n";
  }
  {
    i18n::TranslationRegister t;
    t.id = "key";
    t.value = "Hello";
    t.category = "General";
    t.creationDate = "2024-01-01";
    t.modificationDate = "2024-06-01";
    t.modificationVersion = 2;
    assert(t.id == "key");
    assert(t.value == "Hello");
    assert(t.category == "General");
    assert(t.modificationVersion == 2);
    std::cout << "[PASS] Translation field assignment\n";
  }
  return EXIT_SUCCESS;
}

#endif
