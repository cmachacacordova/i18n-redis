#include <filesystem>
#include <iostream>

#include "i18n/redis/translation_provider.h"
#include "i18n/translation.h"

int main() {
  std::string host = "localhost";
  int port = 6379;
  std::filesystem::path cwd = std::filesystem::current_path();

  i18n::Translation translation(std::make_unique<i18n::RedisTranslationProvider>(host, port), "en");
  translation.store(cwd.string(), {"en"}); // Adjust the path and locales as needed

  std::cout << "Redis value: " << translation.translate("success", "en") << std::endl;
  return 0;
}
