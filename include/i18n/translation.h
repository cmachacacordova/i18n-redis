#pragma once

#include "i18n/configuration.h"

#include <memory>
#include <string>

#include <fmt/core.h>

#include "i18n/translation_provider.h"

namespace i18n {
class I18N_REDIS_EXPORT Translation {
private:
  std::unique_ptr<TranslationProvider> provider;
  std::string defaultLocale;

public:
  Translation(std::unique_ptr<TranslationProvider>, std::string);

  bool store(const std::string &, const std::vector<std::string> &);

  template <typename... Args>
  std::string translate(const std::string &key, const std::string &locale = "", Args &&...args) const {
    std::string usedLocale = locale.empty() ? defaultLocale : locale;
    std::string raw = provider->get(key, usedLocale);
    return fmt::format(raw, std::forward<Args>(args)...);
  }

  std::string translate(const std::string &, const std::string & = "") const;

  ~Translation();
};

} // namespace i18n
