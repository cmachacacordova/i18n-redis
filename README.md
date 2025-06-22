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

En Linux se emplea el triplet `x64-linux-static`, por lo que incluso la
biblioteca compartida incorpora el código de las dependencias y no requiere
archivos externos.

Los presets de CMake ya apuntan al *toolchain* ubicado en `external/vcpkg`, por lo que no es necesario definir `VCPKG_ROOT`. Se usa `clang-cl` en Windows y `clang`/`clang++` en Unix.

Configura y compila la biblioteca eligiendo el preset adecuado. Por ejemplo,
para una compilación optimizada en Linux que produzca solo la versión estática:
```bash
cmake --preset linux-static-release
cmake --build out/linux-static-release
```
Los nombres de preset siguen el patrón `<plataforma>-<tipo>-<modo>` donde
`<tipo>` es `static`, `shared` o `both` y `<modo>` puede ser `debug` o
`release`.

Las variantes `*-both-*` activan `I18N_REDIS_BUILD_BOTH` para construir en un
solo paso las bibliotecas estática y compartida. Las dependencias instaladas por
vcpkg se encuentran en
`out/<preset>/vcpkg_installed/<triplet>/lib` y se añaden automáticamente a las
variables de entorno `LIB` o `LD_LIBRARY_PATH`.
En Windows la biblioteca estática se llama `i18n-redis_static.lib` y la
compartida produce `i18n-redis.dll` junto con `i18n-redis_shared.lib`.
