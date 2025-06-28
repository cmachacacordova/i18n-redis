#pragma once

#include "i18n/configuration.h"

#include "i18n/redis/connection.h"
#include "i18n/translation_provider.h"

namespace i18n {

class I18N_REDIS_EXPORT Translation;

class I18N_REDIS_EXPORT RedisTranslationProvider : public TranslationProvider {
private:
  i18n::redis::Connection connection;

  bool load(const std::string &, const std::vector<std::string> &) const override;

public:
  RedisTranslationProvider(const std::string &, int);

  std::string get(const std::string &, const std::string &) const override;

  ~RedisTranslationProvider() override;

  friend class i18n::Translation;
};
} // namespace i18n
