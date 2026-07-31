#include <filesystem>
#include <iostream>

#include "i18n/Translation.h"
#include "i18n/redis/RedisTranslationProvider.h"

int main() {
  std::string host = "localhost";
  int port = 6379;
  std::filesystem::path cwd = std::filesystem::current_path();

  // Create Translation with explicit default locale
  i18n::Translation t(std::make_unique<i18n::RedisTranslationProvider>(host, port), "en");
  
  // Or use the default locale ("en"):
  // i18n::Translation t(std::make_unique<i18n::RedisTranslationProvider>(host, port));
  
  t.store(cwd.string(), {"en"}); // Adjust the path and locales as needed

  // Translate using default locale
  std::cout << "Redis value: " << t.translate("success") << std::endl;
  
  // Translate with explicit locale
  std::cout << "Redis value (explicit locale): " << t.translate("success", "en") << std::endl;
  
  return 0;
}
