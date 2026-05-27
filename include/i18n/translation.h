#pragma once

#include "i18n/configuration.h"

#include <memory>
#include <string>
#include <vector>

#include <fmt/core.h>

#include "i18n/translation_provider.h"

namespace i18n {
class I18N_REDIS_EXPORT Translation {
private:
  std::unique_ptr<TranslationProvider> provider;
  std::string defaultLocale;

public:
  Translation(std::unique_ptr<TranslationProvider>, std::string defaultLocale);

  bool store(const std::string &cwd, const std::vector<std::string> &locales);

  template <typename... Args>
  std::string translate(const std::string &key, const std::string &locale, Args &&...args) const {
    const std::string &usedLocale = locale.empty() ? defaultLocale : locale;
    const std::string raw = provider->get(key, usedLocale);
    return fmt::vformat(raw, fmt::make_format_args(args...));
  }

  std::string translate(const std::string &key, const std::string &locale = "") const;

  ~Translation() noexcept;
};

} // namespace i18n
