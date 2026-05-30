#ifdef I18N_REDIS_NO_CATCH2

#include <cstdlib>
#include <iostream>

extern int runKeyTests();

int main() {
  int result = EXIT_SUCCESS;
  try {
    result |= runKeyTests();
  } catch (const std::exception &ex) {
    std::cerr << "[ERROR] Unexpected exception: " << ex.what() << '\n';
    return EXIT_FAILURE;
  }
  if (result == EXIT_SUCCESS) {
    std::cout << "All tests passed.\n";
  }
  return result;
}

#endif
