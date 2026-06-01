#include "i18n/Translation.h"

namespace i18n {

Translation::Translation(std::unique_ptr<TranslationProvider> provider, std::string defaultLocale) : m_provider(std::move(provider)), m_default_locale(std::move(defaultLocale)) {
}

bool Translation::store(const std::string &cwd, const std::vector<std::string> &locales) {
  if (!m_provider) {
    return false;
  }

  m_provider->load(cwd, locales);
  return true;
}

std::string Translation::translate(const std::string &key, const std::string &locale) const {
  const std::string &usedLocale = locale.empty() ? m_default_locale : locale;
  return m_provider->get(key, usedLocale);
}

Translation::~Translation() noexcept = default;

} // namespace i18n
