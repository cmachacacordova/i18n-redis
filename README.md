# i18n-redis

Ejemplo de proyecto C++ multiplataforma que utiliza CMake y las dependencias [redis-plus-plus](https://github.com/sewenew/redis-plus-plus) y [nlohmann/json](https://github.com/nlohmann/json).

## Requisitos
- CMake >= 3.14
- Un compilador C++17
- Git y bash para instalar vcpkg.

## Instalar vcpkg
Ejecuta el script `scripts/install_vcpkg.sh` para clonar y compilar vcpkg en
`external/vcpkg`:
```bash
./scripts/install_vcpkg.sh
```

## Compilaci\u00f3n
Instala las dependencias usando los triplets que vienen con vcpkg:
```bash
external/vcpkg/vcpkg install \
  --triplet x64-linux-static   # o x64-linux
external/vcpkg/vcpkg install \
  --triplet x64-windows-static # o x64-windows
```

Los presets de CMake ya apuntan al `toolchain` ubicado en `external/vcpkg`, por
lo que no es necesario definir `VCPKG_ROOT`. Para compilar se utiliza
`clang-cl` en Windows y `clang`/`clang++` en Linux.

Luego configura y compila la biblioteca usando los presets provistos.
Por ejemplo para una compilación optimizada:
```bash
cmake --preset linux-static-release    # o linux-shared-release
cmake --build out/linux-static-release
```
Para un build de depuración utiliza `linux-*-debug`. En Windows se
utilizan los presets `windows-static-{debug,release}` o
`windows-shared-{debug,release}` de manera análoga.

Si necesitas generar tanto la biblioteca estática como la compartida
puedes usar los presets `linux-both-{debug,release}` o
`windows-both-{debug,release}`.

Cuando se compilan las dependencias en modo manifiesto, las bibliotecas
quedan en la carpeta `out/<preset>/vcpkg_installed/<triplet>/lib`.
Los presets agregan esta ruta automáticamente a `LIB` o
`LD_LIBRARY_PATH` para que el enlazador la encuentre.

