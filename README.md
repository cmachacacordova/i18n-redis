# i18n-redis

Ejemplo de biblioteca C++ que utiliza CMake con [redis-plus-plus](https://github.com/sewenew/redis-plus-plus) y [nlohmann/json](https://github.com/nlohmann/json). Las dependencias se gestionan mediante [vcpkg](https://github.com/microsoft/vcpkg) y se enlazan de forma estática.
Cuando se emplean triplets estáticos, vcpkg instala la biblioteca `redis++` con el
nombre `redis++_static`. El `CMakeLists.txt` crea un alias para que ambos casos
funcionen sin modificar el código de usuario.

## Requisitos
- CMake >= 3.14
- Un compilador C++17
- Git y bash para instalar vcpkg.

## Instalar vcpkg
Ejecuta el script `scripts/install_vcpkg.sh` para clonar y compilar vcpkg en `external/vcpkg`:
```bash
./scripts/install_vcpkg.sh
```

## Compilación
Instala las dependencias utilizando los triplets estáticos incluidos en el proyecto:
```bash
external/vcpkg/vcpkg install --triplet x64-linux-static
external/vcpkg/vcpkg install --triplet x64-windows-static-md
```

Los presets de CMake ya apuntan al *toolchain* ubicado en `external/vcpkg`, por lo que no es necesario definir `VCPKG_ROOT`. Se usa `clang-cl` en Windows y `clang`/`clang++` en Unix.

Configura y compila la biblioteca con los presets disponibles. Por ejemplo, para un build optimizado en Linux:
```bash
cmake --preset linux-release
cmake --build out/linux-release
```
Para depuración utiliza `linux-debug`. En Windows se emplean los presets `windows-release` y `windows-debug` de forma análoga.

Cada preset genera tanto la biblioteca estática como la compartida. Las dependencias compiladas por vcpkg quedan en `out/<preset>/vcpkg_installed/<triplet>/lib`, ruta que se añade automáticamente a `LIB` o `LD_LIBRARY_PATH` para el enlazador.
En Windows la biblioteca estática se genera como `i18n-redis_static.lib` y la
versión compartida produce `i18n-redis.dll` junto con `i18n-redis_shared.lib`.
