#include <filesystem>
#include <fstream>
#include <stdexcept>

#include <fmt/core.h>

#include "i18n/configuration.h"
#include "i18n/json.h"
#include "i18n/redis/translation_provider.h"
#include "i18n/types.h"

// ADL serializer for TranslationRegister: maps camelCase JSON field names
// (used in locale files) to the struct's snake_case member variables.
NLOHMANN_JSON_NAMESPACE_BEGIN

template <>
struct adl_serializer<i18n::TranslationRegister> {
  static void to_json(nlohmann::json &j, const i18n::TranslationRegister &t) {
    j["id"] = t.m_id;
    j["value"] = t.m_value;
    j["category"] = t.m_category;
    j["creationDate"] = t.m_creation_date;
    j["modificationDate"] = t.m_modification_date;
    j["modificationVersion"] = t.m_modification_version;
  }
  static void from_json(const nlohmann::json &j, i18n::TranslationRegister &t) {
    j.at("id").get_to(t.m_id);
    j.at("value").get_to(t.m_value);
    j.at("category").get_to(t.m_category);
    j.at("creationDate").get_to(t.m_creation_date);
    j.at("modificationDate").get_to(t.m_modification_date);
    j.at("modificationVersion").get_to(t.m_modification_version);
  }
};

NLOHMANN_JSON_NAMESPACE_END

i18n::RedisTranslationProvider::RedisTranslationProvider(const std::string &host, int port) : m_connection(host, port) {
}

bool i18n::RedisTranslationProvider::load(const std::string &cwd, const std::vector<std::string> &locales) const {
  if (locales.empty()) {
    return false;
  }
  for (const auto &locale : locales) {
    const std::filesystem::path localePath = (std::filesystem::path(cwd) / "locales" / locale).lexically_normal();

    if (!std::filesystem::exists(localePath) || !std::filesystem::is_directory(localePath)) {
      continue;
    }

    for (const auto &entry : std::filesystem::directory_iterator(localePath)) {
      if (!entry.is_regular_file() || entry.path().extension() != ".json") {
        continue;
      }

      std::ifstream file(entry.path());
      if (!file) {
        continue;
      }

      i18n::json j;
      try {
        file >> j;
      } catch (const nlohmann::json::parse_error &e) { throw std::runtime_error(fmt::format("Failed to parse JSON file '{}': {}", entry.path().string(), e.what())); }
      const auto translations = j.get<std::vector<i18n::TranslationRegister>>();

      // Validate every entry before writing to Redis to prevent partial or
      // corrupted data from reaching the store.
      for (const auto &translation : translations) {
        if (translation.m_id.empty()) {
          throw std::runtime_error(fmt::format("Translation ID is empty in file: {}", entry.path().string()));
        }
        if (translation.m_value.empty()) {
          throw std::runtime_error(fmt::format("Translation value is empty for ID '{}' in file: {}", translation.m_id, entry.path().string()));
        }
        if (translation.m_category.empty()) {
          throw std::runtime_error(fmt::format("Translation category is empty for ID '{}' in file: {}", translation.m_id, entry.path().string()));
        }
        if (translation.m_creation_date.empty()) {
          throw std::runtime_error(fmt::format("Translation creationDate is empty for ID '{}' in file: {}", translation.m_id, entry.path().string()));
        }
        if (translation.m_modification_date.empty()) {
          throw std::runtime_error(fmt::format("Translation modificationDate is empty for ID '{}' in file: {}", translation.m_id, entry.path().string()));
        }
        if (translation.m_modification_version < 0) {
          throw std::runtime_error(fmt::format("Translation modificationVersion is negative for ID '{}' in file: {}", translation.m_id, entry.path().string()));
        }
        // Colons are used as namespace separators in I18N_FORMAT_KEY, so
        // they must not appear in the id itself.
        if (translation.m_id.find(':') != std::string::npos) {
          throw std::runtime_error(fmt::format("Translation ID '{}' contains a colon, which is not allowed in Redis keys.", translation.m_id));
        }

        // Build the final Redis key, e.g. "i18n:en:greeting".
        const std::string key = fmt::format(I18N_FORMAT_KEY, locale, translation.m_id);
        this->m_connection.store<i18n::TranslationRegister>(key, translation);
      }
    }
  }
  return true;
}

std::string i18n::RedisTranslationProvider::get(const std::string &key, const std::string &locale) const {
  if (const auto value = this->m_connection.value<i18n::TranslationRegister>(fmt::format(I18N_FORMAT_KEY, locale, key))) {
    return value->m_value;
  }
  // Return the key itself as a safe fallback when no translation is found.
  return key;
}

i18n::RedisTranslationProvider::~RedisTranslationProvider() = default;