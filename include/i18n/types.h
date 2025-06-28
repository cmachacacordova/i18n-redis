#pragma once

#include "i18n/configuration.h"

#include <string>

namespace i18n {
struct translation {
  std::string id;
  std::string value;
  std::string category;
  std::string creationDate;
  std::string modificationDate;
  int version;
};
} // namespace i18n
