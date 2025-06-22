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
Instala las dependencias con el triplet correspondiente usando como overlay
la carpeta `vcpkg/triplets` de este repositorio:
```bash
external/vcpkg/vcpkg install \
  --overlay-triplets=vcpkg/triplets \
  --triplet x64-linux-static   # o x64-linux-shared
external/vcpkg/vcpkg install \
  --overlay-triplets=vcpkg/triplets \
  --triplet x64-windows-static # o x64-windows-shared
```

Los presets de CMake ya apuntan al `toolchain` ubicado en `external/vcpkg`, por
lo que no es necesario definir `VCPKG_ROOT`.

Luego configura y compila la biblioteca usando los presets provistos:
```bash
cmake --preset linux-static    # o linux-shared
cmake --build out/linux-static
```
Para Windows utiliza `windows-static` o `windows-shared` de manera análoga.

