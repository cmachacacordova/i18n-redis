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

## Uso del port de vcpkg
Puedes instalar la biblioteca como un port local ejecutando:
```bash
external/vcpkg/vcpkg install i18n-redis --overlay-ports=ports
```
Luego, en tu proyecto CMake, simplemente usa `find_package(i18n-redis CONFIG REQUIRED)` y enlaza con `i18n-redis::i18n-redis`.

El `portfile.cmake` obtiene el código desde Git usando `vcpkg_from_git`. Puedes
seleccionar una versión específica cambiando la opción `REF` al hash de un
commit o etiqueta del repositorio. Para automatizar este proceso se incluye el
script `scripts/update_port.sh`, que recibe la etiqueta o el hash de commit,
calcula el SHA512 del archivo correspondiente y actualiza `portfile.cmake` y
`vcpkg.json`. En Windows puedes ejecutar `scripts/update_port.ps1` con
PowerShell para lograr lo mismo:

```bash
./scripts/update_port.sh v0.2.1
```
```powershell
./scripts/update_port.ps1 v0.2.1
```

## Compilación
Instala las dependencias para los triplets utilizados por los distintos presets:
```bash
external/vcpkg/vcpkg install --triplet x64-linux-static
external/vcpkg/vcpkg install --triplet x64-linux
external/vcpkg/vcpkg install --triplet x64-windows-static-md
external/vcpkg/vcpkg install --triplet x64-windows
```

Los presets `*-static-*` y `*-both-*` emplean los triplets estáticos. En Linux
esto implica que incluso la biblioteca compartida incorpora el código de las
dependencias y no requiere archivos externos. Las variantes `*-shared-*` usan
los triplets dinámicos (`x64-linux` o `x64-windows`).

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
variables de entorno `LIB` o `LD_LIBRARY_PATH`. Los encabezados quedan en
`out/<preset>/vcpkg_installed/<triplet>/include` y se agregan a `INCLUDE`
(Windows) o `CPATH` (Unix). Cada preset define `VCPKG_TARGET_TRIPLET`,
por lo que esas rutas siempre usan el triplet adecuado.
En Windows la biblioteca estática se llama `i18n-redis_static.lib` y la
compartida produce `i18n-redis.dll` junto con `i18n-redis_shared.lib`.

La lógica de configuración de CMake se divide en los archivos
`scripts/cmake/Dependencies.cmake` y `scripts/cmake/Targets.cmake`,
incluidos desde el `CMakeLists.txt` principal para mantener el proyecto ordenado.

Al configurar el proyecto, CMake genera el archivo `i18n_redis_export.h` en el
directorio de compilación. Este encabezado define el macro
`I18N_REDIS_EXPORT` que se utiliza para exportar correctamente las funciones de
la biblioteca cuando se crea la versión compartida.

## Ejemplo
Se incluye una pequeña aplicación en `example/` que utiliza la biblioteca. Tras compilar el proyecto puedes ejecutarla con:
```bash
./i18n-redis-example <clave>
```
La aplicación almacenará un mensaje en Redis con la clave indicada y mostrará el valor recuperado.

## Detecci\u00f3n autom\u00e1tica de archivos fuente
El proyecto usa `file(GLOB CONFIGURE_DEPENDS ...)` para incluir todos los
archivos `.cpp` del directorio `src`. Cuando a\u00f1adas nuevos archivos,
CMake volver\u00e1 a configurarse autom\u00e1ticamente al invocar la compilaci\u00f3n y
se compilar\u00e1n sin editar el `CMakeLists.txt`.
