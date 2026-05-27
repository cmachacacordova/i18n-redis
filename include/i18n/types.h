#pragma once

#include "i18n/configuration.h"

#include <string>

namespace i18n {
struct Translation {
  std::string id;
  std::string value;
  std::string category;
  std::string creationDate;
  std::string modificationDate;
  int modificationVersion{0};
};
} // namespace i18n
