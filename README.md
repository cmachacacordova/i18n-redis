# i18n-redis

Biblioteca C++ de internacionalización (i18n) que almacena y recupera traducciones desde Redis. Utiliza CMake con [redis-plus-plus](https://github.com/sewenew/redis-plus-plus) para la conexión a Redis, [nlohmann/json](https://github.com/nlohmann/json) para el procesamiento de archivos JSON y [fmt](https://github.com/fmtlib/fmt) para el formateo de cadenas.

Las dependencias se gestionan mediante [vcpkg](https://github.com/microsoft/vcpkg) y se enlazan de forma estática. Cuando se emplean triplets estáticos, vcpkg instala la biblioteca `redis++` con el nombre `redis++_static`. El `CMakeLists.txt` crea un alias para que ambos casos funcionen sin modificar el código de usuario.

## Requisitos
- CMake >= 3.14
- Un compilador C++17
- Git y bash para instalar vcpkg
- Servidor Redis en ejecución

## Instalación

### Instalar vcpkg
Ejecuta el script `scripts/install_vcpkg.sh` para clonar y compilar vcpkg en `external/vcpkg`:
```bash
./scripts/install_vcpkg.sh
```

### Compilación
Instala las dependencias para los triplets utilizados por los distintos presets:
```bash
external/vcpkg/vcpkg install --triplet x64-linux-static
external/vcpkg/vcpkg install --triplet x64-linux
external/vcpkg/vcpkg install --triplet x64-windows-static-md
external/vcpkg/vcpkg install --triplet x64-windows
```

Los presets `*-static-*` emplean los triplets estáticos. En Linux esto implica que incluso la biblioteca compartida incorpora el código de las dependencias y no requiere archivos externos. Las variantes `*-shared-*` usan los triplets dinámicos (`x64-linux` o `x64-windows`).

Los presets de CMake ya apuntan al *toolchain* ubicado en `external/vcpkg`, por lo que no es necesario definir `VCPKG_ROOT`. Se usa `clang-cl` en Windows y `clang`/`clang++` en Unix.

Configura y compila la biblioteca eligiendo el preset adecuado. Por ejemplo, para una compilación optimizada en Linux que produzca solo la versión estática:
```bash
cmake --preset linux-static-release
cmake --build out/linux-static-release
```
Los nombres de preset siguen el patrón `<plataforma>-<tipo>-<modo>` donde `<tipo>` es `static` o `shared` y `<modo>` puede ser `debug` o `release`.

Como alternativa, ejecuta `scripts/build_project.sh` o `scripts/build_project.bat` para instalar vcpkg y compilar de forma automática. El primer argumento indica el tipo de biblioteca (`static` o `shared`) y el segundo el modo (`release` o `debug`). Por ejemplo:
```bash
./scripts/build_project.sh static release
```

Las dependencias instaladas por vcpkg se encuentran en `out/<preset>/vcpkg_installed/<triplet>/lib` y se añaden automáticamente a las variables de entorno `LIB` o `LD_LIBRARY_PATH`. Los encabezados quedan en `out/<preset>/vcpkg_installed/<triplet>/include` y se agregan a `INCLUDE` (Windows) o `CPATH` (Unix). Cada preset define `VCPKG_TARGET_TRIPLET`, por lo que esas rutas siempre usan el triplet adecuado.

En Windows la biblioteca estática se llama `i18n-redis_static.lib` y la compartida produce `i18n-redis.dll` junto con `i18n-redis_shared.lib`.

La lógica de configuración de CMake se divide en los archivos `scripts/cmake/Dependencies.cmake` y `scripts/cmake/Targets.cmake`, incluidos desde el `CMakeLists.txt` principal para mantener el proyecto ordenado.

Al configurar el proyecto, CMake genera el archivo `i18n_redis_export.h` en el directorio de compilación. Este encabezado define el macro `I18N_REDIS_EXPORT` que se utiliza para exportar correctamente las funciones de la biblioteca cuando se crea la versión compartida. El archivo también se instala junto con el resto de los encabezados, de modo que otros proyectos puedan utilizar la biblioteca sin problemas.

## Uso de la librería

### Incluir los encabezados

```cpp
#include "i18n/translation.h"
#include "i18n/redis/translation_provider.h"
```

### Crear un proveedor Redis

La clase `RedisTranslationProvider` gestiona la conexión y operaciones con Redis:

```cpp
std::unique_ptr<i18n::TranslationProvider> provider = 
    std::make_unique<i18n::RedisTranslationProvider>("localhost", 6379);
```

### Crear el gestor de traducciones

La clase `Translation` utiliza un proveedor para cargar y recuperar traducciones:

```cpp
i18n::Translation translation(std::move(provider), "en");
```

El segundo parámetro especifica el idioma por defecto (por ejemplo, "en" para inglés).

### Cargar traducciones

Para cargar traducciones desde archivos JSON locales a Redis:

```cpp
translation.store("/ruta/a/locales", {"en", "es", "fr"});
```

El método `store` recibe:
- Ruta al directorio que contiene las carpetas de idiomas
- Vector con los códigos de idioma a cargar

### Formato de archivos de traducción

Los archivos JSON deben ubicarse en subdirectorios por idioma (ej: `locales/en/messages.json`) y seguir este formato:

```json
[
  {
    "id": "success",
    "value": "Operation completed successfully",
    "category": "Client",
    "creationDate": "2024-06-28",
    "modificationDate": "2024-06-28",
    "modificationVersion": 1
  },
  {
    "id": "error",
    "value": "An error occurred",
    "category": "Client",
    "creationDate": "2024-06-28",
    "modificationDate": "2024-06-28",
    "modificationVersion": 1
  }
]
```

### Traducir mensajes

Para obtener una traducción por clave:

```cpp
// Usa el idioma por defecto
std::string msg = translation.translate("success");

// Especifica un idioma diferente
std::string msg = translation.translate("success", "es");
```

### Formateo con parámetros

La biblioteca soporta formateo de cadenas con `fmt`. Incluye placeholders en los valores:

```json
{
  "id": "welcome",
  "value": "Welcome, {0}! You have {1} messages."
}
```

Y pasa los argumentos al traducir:

```cpp
std::string msg = translation.translate("welcome", "en", "John", 5);
// Resultado: "Welcome, John! You have 5 messages."
```

### Ejemplo completo

```cpp
#include <iostream>
#include <filesystem>
#include "i18n/translation.h"
#include "i18n/redis/translation_provider.h"

int main() {
    // Crear proveedor Redis
    std::unique_ptr<i18n::TranslationProvider> provider = 
        std::make_unique<i18n::RedisTranslationProvider>("localhost", 6379);
    
    // Crear gestor de traducciones
    i18n::Translation translation(std::move(provider), "en");
    
    // Cargar traducciones desde archivos locales
    std::filesystem::path cwd = std::filesystem::current_path();
    translation.store(cwd.string(), {"en"});
    
    // Usar traducciones
    std::cout << translation.translate("success", "en") << std::endl;
    
    return 0;
}
```

## Ejemplo incluido

Se incluye una pequeña aplicación en `example/` que utiliza la biblioteca. Tras compilar el proyecto puedes ejecutarla con:
```bash
./i18n-redis-example
```

La aplicación almacenará mensajes en Redis desde los archivos locales y mostrará los valores recuperados.

## Detección automática de archivos fuente

El proyecto usa `file(GLOB CONFIGURE_DEPENDS ...)` para incluir todos los archivos `.cpp` del directorio `src`. Cuando añadas nuevos archivos, CMake volverá a configurarse automáticamente al invocar la compilación y se compilarán sin editar el `CMakeLists.txt`.

## Uso con vcpkg en otros proyectos

Para utilizar esta biblioteca como dependencia en tu proyecto mediante vcpkg:

### 1. Copiar los archivos de la biblioteca al registry de vcpkg

Después de compilar e instalar la librería, copia los archivos necesarios al directorio de vcpkg para que estén disponibles como dependencia:

```bash
# Linux
mkdir -p external/vcpkg/installed/x64-linux-static/include/i18n
cp include/i18n/*.h external/vcpkg/installed/x64-linux-static/include/i18n/
cp -r include/i18n/redis external/vcpkg/installed/x64-linux-static/include/i18n/
cp out/linux-static-release/i18n_redis_export.h external/vcpkg/installed/x64-linux-static/include/
cp out/linux-static-release/libi18n-redis.a external/vcpkg/installed/x64-linux-static/lib/
```

### 2. Referenciar en tu vcpkg.json

```json
{
  "name": "mi-proyecto",
  "version": "1.0.0",
  "dependencies": [
    "nlohmann-json",
    "redis-plus-plus",
    "fmt",
    {
      "name": "i18n-redis",
      "platform": "!(windows & arm)"
    }
  ]
}
```

### 3. Configurar CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.14)
project(mi-proyecto LANGUAGES CXX)

find_package(nlohmann_json CONFIG REQUIRED)
find_package(redis++ CONFIG REQUIRED)
find_package(fmt CONFIG REQUIRED)

add_executable(mi-app main.cpp)

target_link_libraries(mi-app PRIVATE
    nlohmann_json::nlohmann_json
    redis++::redis++_static
    fmt::fmt
    i18n-redis_static
)
```

### 4. Opción: Crear un overlay port

Para un control más robusto, puedes crear un *overlay port* en tu proyecto:

**vcpkg-overlay-ports/i18n-redis/portfile.cmake:**
```cmake
vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://github.com/usuario/i18n-redis.git
    REF v0.3.1
)

vcpkg_cmake_configure(SOURCE_PATH ${SOURCE_PATH})
vcpkg_cmake_install()
vcpkg_cmake_config_fixup()
```

**vcpkg-overlay-ports/i18n-redis/vcpkg.json:**
```json
{
  "name": "i18n-redis",
  "version": "0.3.1",
  "dependencies": [
    "nlohmann-json",
    "redis-plus-plus",
    "fmt"
  ]
}
```

Usa el overlay en tu configuración de CMake:
```bash
cmake -B build -S . -DVCPKG_OVERLAY_PORTS=./vcpkg-overlay-ports
```
