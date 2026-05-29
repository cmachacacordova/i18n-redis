#include "i18n/types.h"

#include <cassert>
#include <cstdlib>
#include <iostream>
#include <string>

#ifndef I18N_REDIS_NO_CATCH2
#include <catch2/catch_test_macros.hpp>

TEST_CASE("Translation struct default initialisation", "[types]") {
  i18n::TranslationRegister t;
  REQUIRE(t.m_id.empty());
  REQUIRE(t.m_value.empty());
  REQUIRE(t.m_category.empty());
  REQUIRE(t.m_creation_date.empty());
  REQUIRE(t.m_modification_date.empty());
  REQUIRE(t.m_modification_version == 0);
}

TEST_CASE("Translation struct field assignment", "[types]") {
  i18n::TranslationRegister t;
  t.m_id = "key";
  t.m_value = "Hello";
  t.m_category = "General";
  t.m_creation_date = "2024-01-01";
  t.m_modification_date = "2024-06-01";
  t.m_modification_version = 2;

  REQUIRE(t.m_id == "key");
  REQUIRE(t.m_value == "Hello");
  REQUIRE(t.m_category == "General");
  REQUIRE(t.m_modification_version == 2);
}

#else

int runTests() {
  {
    i18n::TranslationRegister t;
    assert(t.m_id.empty());
    assert(t.m_value.empty());
    assert(t.m_category.empty());
    assert(t.m_creation_date.empty());
    assert(t.m_modification_date.empty());
    assert(t.m_modification_version == 0);
    std::cout << "[PASS] Translation default initialisation\n";
  }
  {
    i18n::TranslationRegister t;
    t.m_id = "key";
    t.m_value = "Hello";
    t.m_category = "General";
    t.m_creation_date = "2024-01-01";
    t.m_modification_date = "2024-06-01";
    t.m_modification_version = 2;
    assert(t.m_id == "key");
    assert(t.m_value == "Hello");
    assert(t.m_category == "General");
    assert(t.m_modification_version == 2);
    std::cout << "[PASS] Translation field assignment\n";
  }
  return EXIT_SUCCESS;
}

#endif
