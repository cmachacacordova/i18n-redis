# i18n-redis

Ejemplo de proyecto C++ multiplataforma que utiliza CMake y las dependencias [redis-plus-plus](https://github.com/sewenew/redis-plus-plus) y [nlohmann/json](https://github.com/nlohmann/json).

## Requisitos
- CMake >= 3.14
- Un compilador C++17

## Compilaci\u00f3n
Las dependencias se descargan autom\u00e1ticamente mediante
[FetchContent](https://cmake.org/cmake/help/latest/module/FetchContent.html),
por lo que no es necesario instalarlas manualmente.

Configura y compila la biblioteca usando los presets provistos:
```bash
cmake --preset linux-static    # o linux-shared
cmake --build out/linux-static
```
Para Windows utiliza `windows-static` o `windows-shared` de manera an\u00e1loga.
