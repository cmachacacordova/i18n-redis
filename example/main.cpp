#include <filesystem>
#include <iostream>

#include "i18n/redis/translation_provider.h"
#include "i18n/translation.h"

int main(int argc, char **argv) {
  std::string host = "localhost";
  int port = 6379;
  std::filesystem::path cwd = std::filesystem::current_path();
  std::unique_ptr<i18n::TranslationProvider> provider = std::make_unique<i18n::RedisTranslationProvider>(host, port);
  i18n::Translation translation(std::move(provider), "en");
  translation.store(cwd.string(), {"en"}); // Adjust the path and locales as needed
  std::cout << "Redis value: " << translation.translate("success", "en") << std::endl;
  return 0;
}
