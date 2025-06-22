#include "i18n_redis.h"
#include <iostream>

int main(int argc, char** argv) {
    if (argc != 2) {
        std::cerr << "Uso: " << argv[0] << " <clave>\n";
        return 1;
    }
    i18n_redis::store_message(argv[1]);
    return 0;
}
