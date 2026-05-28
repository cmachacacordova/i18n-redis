#include "i18n/translation.h"

i18n::Translation::Translation(std::unique_ptr<TranslationProvider> provider_, std::string defaultLocale_) : provider(std::move(provider_)), defaultLocale(std::move(defaultLocale_)) {
}

bool i18n::Translation::store(const std::string &cwd, const std::vector<std::string> &locales) {
  if (this->provider) {
    return this->provider->load(cwd, locales);
  }
  return false;
}

std::string i18n::Translation::translate(const std::string &key, const std::string &locale) const {
  const std::string &usedLocale = locale.empty() ? defaultLocale : locale;
  return provider->get(key, usedLocale);
}

i18n::Translation::~Translation() noexcept = default;
