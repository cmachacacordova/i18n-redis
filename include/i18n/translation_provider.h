#pragma once

#include "i18n/configuration.h"

#include <string>
#include <vector>

namespace i18n {
class I18N_REDIS_EXPORT TranslationProvider {

public:
  TranslationProvider();

  virtual std::string get(const std::string &, const std::string & = "en") const = 0;

  virtual bool load(const std::string &, const std::vector<std::string> &) const = 0; // Assuming a method to load translations, can be overridden by derived classes

  virtual ~TranslationProvider();
};

} // namespace i18n
