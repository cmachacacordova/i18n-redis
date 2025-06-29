#include <filesystem>
#include <fstream>

#include <fmt/core.h>

#include "i18n/json.h"
#include "i18n/redis/translation_provider.h"
#include "i18n/types.h"

#if defined _WIN32 || defined __CYGWIN__
char preferred_separator = '\\';
#else
char preferred_separator = '/';
#endif

NLOHMANN_JSON_NAMESPACE_BEGIN

template <>
struct adl_serializer<i18n::translation> {
  static void to_json(nlohmann::json &nlohmann_json_j, const i18n::translation &nlohmann_json_t) {
    nlohmann_json_j["id"] = nlohmann_json_t.id;
    nlohmann_json_j["value"] = nlohmann_json_t.value;
    nlohmann_json_j["category"] = nlohmann_json_t.category;
    nlohmann_json_j["creationDate"] = nlohmann_json_t.creationDate;
    nlohmann_json_j["modificationDate"] = nlohmann_json_t.modificationDate;
    nlohmann_json_j["version"] = nlohmann_json_t.version;
  }
  static void from_json(const nlohmann::json &nlohmann_json_j, i18n::translation &nlohmann_json_t) {
    nlohmann_json_j.at("id").get_to(nlohmann_json_t.id);
    nlohmann_json_j.at("value").get_to(nlohmann_json_t.value);
    nlohmann_json_j.at("category").get_to(nlohmann_json_t.category);
    nlohmann_json_j.at("creationDate").get_to(nlohmann_json_t.creationDate);
    nlohmann_json_j.at("modificationDate").get_to(nlohmann_json_t.modificationDate);
    nlohmann_json_j.at("version").get_to(nlohmann_json_t.version);
  }
};

NLOHMANN_JSON_NAMESPACE_END

I18N_REDIS_EXPORT i18n::RedisTranslationProvider::RedisTranslationProvider(const std::string &host, int port) : connection(host, port) {
}

bool i18n::RedisTranslationProvider::load(const std::string &cwd, const std::vector<std::string> &locales) const {

  std::for_each(locales.begin(), locales.end(), [&](const auto &locale) {
    std::string localeDirectory = fmt::format("{}{}locales{}{}", cwd, preferred_separator, preferred_separator, locale);
    std::filesystem::path path = std::filesystem::path(localeDirectory).lexically_normal();
    if (std::filesystem::exists(path) && std::filesystem::is_directory(path)) {
      for (const auto &entry : std::filesystem::directory_iterator(path)) {
        if (entry.is_regular_file() && entry.path().extension() == ".json") {
          std::ifstream file(entry.path());
          if (file) {
            i18n::json j;
            file >> j;
            std::vector<i18n::translation> translations = j.get<std::vector<i18n::translation>>();
            std::for_each(translations.begin(), translations.end(), [&](const i18n::translation &translation) {
              // Store each translation in Redis with a key based on locale and translation ID
              if (translation.id.empty()) {
                throw std::runtime_error(fmt::format("Translation ID is empty in file: {}", entry.path().string()));
              }
              if (translation.value.empty()) {
                throw std::runtime_error(fmt::format("Translation value is empty for ID: {} in file: {}", translation.id, entry.path().string()));
              }
              if (translation.category.empty()) {
                throw std::runtime_error(fmt::format("Translation category is empty for ID: {} in file: {}", translation.id, entry.path().string()));
              }
              if (translation.creationDate.empty()) {
                throw std::runtime_error(fmt::format("Translation creation date is empty for ID: {} in file: {}", translation.id, entry.path().string()));
              }
              if (translation.modificationDate.empty()) {
                throw std::runtime_error(fmt::format("Translation modification date is empty for ID: {} in file: {}", translation.id, entry.path().string()));
              }
              if (translation.version < 0) {
                throw std::runtime_error(fmt::format("Translation version is negative for ID: {} in file: {}", translation.id, entry.path().string()));
              }
              // Store the translation in Redis
              // Using a key format like "i18n:locale:translation_id"
              if (translation.id.find(':') != std::string::npos) {
                throw std::runtime_error(fmt::format("Translation ID '{}' contains a colon, which is not allowed in Redis keys.", translation.id));
              }
              std::string key = fmt::format(I18N_FORMAT_KEY, locale, translation.id);
              this->connection.store<i18n::translation>(key, translation);
            });
          }
        }
      }
    }
  });
  return false;
}

std::string i18n::RedisTranslationProvider::get(const std::string &key, const std::string &locale) const {
  if (std::optional<i18n::translation> value = this->connection.value<i18n::translation>(fmt::format(I18N_FORMAT_KEY, locale, key))) {
    return (*value).value;
  }
  return key;
}

I18N_REDIS_EXPORT i18n::RedisTranslationProvider::~RedisTranslationProvider() = default;