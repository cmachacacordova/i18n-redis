#include <filesystem>
#include <fstream>
#include <stdexcept>

#include <fmt/core.h>

#include "i18n/json.h"
#include "i18n/redis/translation_provider.h"
#include "i18n/types.h"

NLOHMANN_JSON_NAMESPACE_BEGIN

template <>
struct adl_serializer<i18n::TranslationRegister> {
  static void to_json(nlohmann::json &j, const i18n::TranslationRegister &t) {
    j["id"] = t.id;
    j["value"] = t.value;
    j["category"] = t.category;
    j["creationDate"] = t.creationDate;
    j["modificationDate"] = t.modificationDate;
    j["modificationVersion"] = t.modificationVersion;
  }
  static void from_json(const nlohmann::json &j, i18n::TranslationRegister &t) {
    j.at("id").get_to(t.id);
    j.at("value").get_to(t.value);
    j.at("category").get_to(t.category);
    j.at("creationDate").get_to(t.creationDate);
    j.at("modificationDate").get_to(t.modificationDate);
    j.at("modificationVersion").get_to(t.modificationVersion);
  }
};

NLOHMANN_JSON_NAMESPACE_END

i18n::RedisTranslationProvider::RedisTranslationProvider(const std::string &host, int port) : connection(host, port) {
}

bool i18n::RedisTranslationProvider::load(const std::string &cwd, const std::vector<std::string> &locales) const {
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
      file >> j;
      const auto translations = j.get<std::vector<i18n::TranslationRegister>>();

      for (const auto &translation : translations) {
        if (translation.id.empty()) {
          throw std::runtime_error(fmt::format("Translation ID is empty in file: {}", entry.path().string()));
        }
        if (translation.value.empty()) {
          throw std::runtime_error(fmt::format("Translation value is empty for ID '{}' in file: {}", translation.id, entry.path().string()));
        }
        if (translation.category.empty()) {
          throw std::runtime_error(fmt::format("Translation category is empty for ID '{}' in file: {}", translation.id, entry.path().string()));
        }
        if (translation.creationDate.empty()) {
          throw std::runtime_error(fmt::format("Translation creationDate is empty for ID '{}' in file: {}", translation.id, entry.path().string()));
        }
        if (translation.modificationDate.empty()) {
          throw std::runtime_error(fmt::format("Translation modificationDate is empty for ID '{}' in file: {}", translation.id, entry.path().string()));
        }
        if (translation.modificationVersion < 0) {
          throw std::runtime_error(fmt::format("Translation modificationVersion is negative for ID '{}' in file: {}", translation.id, entry.path().string()));
        }
        if (translation.id.find(':') != std::string::npos) {
          throw std::runtime_error(fmt::format("Translation ID '{}' contains a colon, which is not allowed in Redis keys.", translation.id));
        }

        const std::string key = fmt::format(I18N_FORMAT_KEY, locale, translation.id);
        this->connection.store<i18n::TranslationRegister>(key, translation);
      }
    }
  }
  return true;
}

std::string i18n::RedisTranslationProvider::get(const std::string &key, const std::string &locale) const {
  if (const auto value = this->connection.value<i18n::TranslationRegister>(fmt::format(I18N_FORMAT_KEY, locale, key))) {
    return value->value;
  }
  return key;
}

i18n::RedisTranslationProvider::~RedisTranslationProvider() = default;