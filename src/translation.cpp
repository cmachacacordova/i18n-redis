#include "i18n/translation.h"

i18n::Translation::Translation(std::unique_ptr<TranslationProvider> provider_, std::string defaultLocale_) : m_provider(std::move(provider_)), m_default_locale(std::move(defaultLocale_)) {
}

bool i18n::Translation::store(const std::string &cwd, const std::vector<std::string> &locales) {
  // Guard against a null provider; returns false so callers can detect the failure.
  if (this->m_provider) {
    return this->m_provider->load(cwd, locales);
  }
  return false;
}

std::string i18n::Translation::translate(const std::string &key, const std::string &locale) const {
  // Resolve locale before delegating to the provider.
  const std::string &usedLocale = locale.empty() ? m_default_locale : locale;
  return m_provider->get(key, usedLocale);
}

i18n::Translation::~Translation() noexcept = default;
