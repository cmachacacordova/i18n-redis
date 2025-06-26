#include <iostream>

#include "i18n/i18n_redis.h"

int main(int argc, char **argv) {
  if (argc != 2) {
    std::cerr << "Uso: " << argv[0] << " <clave>\n";
    return 1;
  }

  std::string key = argv[1];
  std::string value = "Hello from C++ Redis client!";

  i18n::redis::Connection connection("localhost", 6379); // Default connection to Redis at localhost:6379
  std::string result = connection.store(key, value);

  result = connection.value<std::string>(key);

  std::cout << "Redis value: " << result << std::endl;

  i18n::redis::store_message(key);

  std::cout << "Redis value: " << connection.value<i18n::json>("test1").dump() << std::endl;

  return 0;
}
