#include <filesystem>
#include <stdexcept>

#include "i18n/Configuration.h"
#include "i18n/redis/RedisTranslationProvider.h"

#include <fmt/core.h>
#include <sw/redis++/redis++.h>
#ifdef I18N_REDIS_USE_SIMDJSON
#include <simdjson.h>
#elif defined(I18N_REDIS_USE_YYJSON)
#include <yyjson.h>
#endif

i18n::RedisTranslationProvider::RedisTranslationProvider(const std::string &host, int port) {
  try {
    sw::redis::ConnectionOptions connection_opts;
    connection_opts.host = host;
    connection_opts.port = port;

    sw::redis::ConnectionPoolOptions pool_opts;
    pool_opts.size = 4;
    pool_opts.wait_timeout = std::chrono::milliseconds(1000);
    pool_opts.connection_lifetime = std::chrono::milliseconds(60000);
    pool_opts.connection_idle_time = std::chrono::milliseconds(30000);

    m_redis = std::make_unique<sw::redis::Redis>(connection_opts, pool_opts);
  } catch (const std::exception &e) { throw std::runtime_error(std::string("Failed to connect to Redis: ") + e.what()); } catch (...) {
    throw std::runtime_error("Failed to connect to Redis: unknown error");
  }
}

i18n::RedisTranslationProvider::RedisTranslationProvider(const sw::redis::ConnectionOptions &connection_opts, const sw::redis::ConnectionPoolOptions &pool_opts) {
  try {
    m_redis = std::make_unique<sw::redis::Redis>(connection_opts, pool_opts);
  } catch (const std::exception &e) { throw std::runtime_error(std::string("Failed to connect to Redis: ") + e.what()); } catch (...) {
    throw std::runtime_error("Failed to connect to Redis: unknown error");
  }
}

bool i18n::RedisTranslationProvider::load(const std::string &cwd, const std::vector<std::string> &locales) {
  bool all_locales_loaded = locales.size() > 0;
  for (const auto &locale : locales) {
    const std::filesystem::path locale_path = (std::filesystem::path(cwd) / "locales" / locale).lexically_normal();

    if (!std::filesystem::exists(locale_path) || !std::filesystem::is_directory(locale_path)) {
      all_locales_loaded &= false;
      continue;
    }

    for (const auto &entry : std::filesystem::directory_iterator(locale_path)) {
      if (!entry.is_regular_file() || entry.path().extension() != ".json") {
        continue;
      }

#ifdef I18N_REDIS_USE_SIMDJSON
      using namespace simdjson;

      ondemand::parser parser;
      padded_string json = padded_string::load(entry.path().string());
      ondemand::document doc = parser.iterate(json);

      size_t index = 0;
      for (ondemand::object obj : doc.get_array()) {
        // raw_json() consumes the object, so capture it first, then reset() to re-iterate fields.
        std::string raw_json(obj.raw_json().value());
        obj.reset();

        std::string_view id;
        if (obj["id"].get_string().get(id)) {
          throw std::runtime_error(fmt::format("Translation 'id' missing or not a string in file {}, index {}", entry.path().string(), index));
        }
        // Copy id before any further field access that may invalidate the string_view.
        std::string id_str(id);

        if (id_str.find(':') != std::string::npos) {
          throw std::runtime_error(fmt::format("Translation ID '{}' contains a colon, which is not allowed in Redis keys.", id_str));
        }
        if (obj["value"].error()) {
          throw std::runtime_error(fmt::format("Translation 'value' missing for ID '{}' in file {}, index {}", id_str, entry.path().string(), index));
        }
        if (obj["category"].error()) {
          throw std::runtime_error(fmt::format("Translation 'category' missing for ID '{}' in file {}, index {}", id_str, entry.path().string(), index));
        }
        if (obj["creationDate"].error()) {
          throw std::runtime_error(fmt::format("Translation 'creationDate' missing for ID '{}' in file {}, index {}", id_str, entry.path().string(), index));
        }
        if (obj["modificationDate"].error()) {
          throw std::runtime_error(fmt::format("Translation 'modificationDate' missing for ID '{}' in file {}, index {}", id_str, entry.path().string(), index));
        }
        if (obj["modificationVersion"].error()) {
          throw std::runtime_error(fmt::format("Translation 'modificationVersion' missing for ID '{}' in file {}, index {}", id_str, entry.path().string(), index));
        }

        const std::string redis_key = fmt::format(i18n::kFormatKey, locale, id_str);
        this->m_redis->set(redis_key, raw_json);
        ++index;
      }
#elif defined(I18N_REDIS_USE_YYJSON)
      yyjson_doc *doc = yyjson_read_file(entry.path().string().c_str(), YYJSON_READ_NOFLAG, nullptr, nullptr);
      if (!doc) {
        throw std::runtime_error(fmt::format("Failed to parse JSON file: {}", entry.path().string()));
      }

      yyjson_val *root = yyjson_doc_get_root(doc);
      if (!yyjson_is_arr(root)) {
        yyjson_doc_free(doc);
        throw std::runtime_error(fmt::format("Expected JSON array in file: {}", entry.path().string()));
      }

      size_t index = 0;
      yyjson_val *obj;
      yyjson_arr_iter iter = yyjson_arr_iter_with(root);
      while ((obj = yyjson_arr_iter_next(&iter))) {
        yyjson_val *id_val = yyjson_obj_get(obj, "id");
        if (!id_val || !yyjson_is_str(id_val)) {
          yyjson_doc_free(doc);
          throw std::runtime_error(fmt::format("Translation 'id' missing or not a string in file {}, index {}", entry.path().string(), index));
        }
        std::string_view id = yyjson_get_str(id_val);
        if (id.find(':') != std::string::npos) {
          yyjson_doc_free(doc);
          throw std::runtime_error(fmt::format("Translation ID '{}' contains a colon, which is not allowed in Redis keys.", id));
        }

        yyjson_val *value_val = yyjson_obj_get(obj, "value");
        if (!value_val || !yyjson_is_str(value_val)) {
          yyjson_doc_free(doc);
          throw std::runtime_error(fmt::format("Translation 'value' missing for ID '{}' in file {}, index {}", id, entry.path().string(), index));
        }
        if (!yyjson_obj_get(obj, "category")) {
          yyjson_doc_free(doc);
          throw std::runtime_error(fmt::format("Translation 'category' missing for ID '{}' in file {}, index {}", id, entry.path().string(), index));
        }
        if (!yyjson_obj_get(obj, "creationDate")) {
          yyjson_doc_free(doc);
          throw std::runtime_error(fmt::format("Translation 'creationDate' missing for ID '{}' in file {}, index {}", id, entry.path().string(), index));
        }
        if (!yyjson_obj_get(obj, "modificationDate")) {
          yyjson_doc_free(doc);
          throw std::runtime_error(fmt::format("Translation 'modificationDate' missing for ID '{}' in file {}, index {}", id, entry.path().string(), index));
        }
        yyjson_val *ver_val = yyjson_obj_get(obj, "modificationVersion");
        if (!ver_val || !yyjson_is_int(ver_val)) {
          yyjson_doc_free(doc);
          throw std::runtime_error(fmt::format("Translation 'modificationVersion' missing or not an integer for ID '{}' in file {}, index {}", id, entry.path().string(), index));
        }

        const std::string redis_key = fmt::format(i18n::kFormatKey, locale, id);
        size_t json_len = 0;
        char *json_str = yyjson_val_write(obj, YYJSON_WRITE_NOFLAG, &json_len);
        this->m_redis->set(redis_key, std::string(json_str, json_len));
        free(json_str);
        ++index;
      }
      yyjson_doc_free(doc);
#endif
    }
  }
  return all_locales_loaded;
}

std::string i18n::RedisTranslationProvider::get(const std::string &key, const std::string &locale) const {
  auto raw = this->m_redis->get(fmt::format(i18n::kFormatKey, locale, key));
  if (!raw) {
    return key;
  }

#ifdef I18N_REDIS_USE_SIMDJSON
  simdjson::ondemand::parser parser;
  simdjson::padded_string padded(*raw);
  auto doc = parser.iterate(padded);
  std::string_view value;
  if (doc["value"].get_string().get(value)) {
    return key;
  }
  return std::string(value);
#elif defined(I18N_REDIS_USE_YYJSON)
  yyjson_doc *doc = yyjson_read(raw->c_str(), raw->size(), YYJSON_READ_NOFLAG);
  if (!doc) {
    return key;
  }
  yyjson_val *value_val = yyjson_obj_get(yyjson_doc_get_root(doc), "value");
  std::string result = (value_val && yyjson_is_str(value_val)) ? yyjson_get_str(value_val) : key;
  yyjson_doc_free(doc);
  return result;
#else
  return key;
#endif
}

i18n::RedisTranslationProvider::~RedisTranslationProvider() noexcept = default;