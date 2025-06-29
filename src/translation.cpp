#include "i18n/translation.h"

I18N_REDIS_EXPORT i18n::Translation::Translation(std::unique_ptr<TranslationProvider> provider, std::string defaultLocale) : provider(std::move(provider)), defaultLocale(std::move(defaultLocale)) {
}

bool i18n::Translation::store(const std::string &cwd, const std::vector<std::string> &locales) {
  if (this->provider) {
    // Assuming the provider has a store method to persist translations
    return this->provider->load(cwd, locales);
  }
  return false;
}

std::string i18n::Translation::translate(const std::string &key, const std::string &locale) const {
  std::string usedLocale = locale.empty() ? defaultLocale : locale;
  return provider->get(key, usedLocale);
}

I18N_REDIS_EXPORT i18n::Translation::~Translation() = default;
