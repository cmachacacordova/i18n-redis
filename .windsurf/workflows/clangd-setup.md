---
description: Configurar clangd para proyectos C++ con CMake en Windsurf
---

# Configuración de clangd para Proyectos C++

Este documento describe cómo configurar `clangd` correctamente para proyectos C++ que usan CMake como sistema de build.

## Problema Común: Headers no encontrados

Cuando clangd reporta errores como:

```
'core/http/MojangClient.h' file not found
```

Aunque el archivo existe y el proyecto compila correctamente con CMake.

## Solución Portátil

### 1. Generar `compile_commands.json`

CMake debe generar la base de datos de compilación:

```bash
cmake -B out/build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
# o si ya tienes un preset:
cmake --preset=your-preset
```

Verifica que se creó el archivo:

```bash
ls out/build/compile_commands.json
```

### 2. Configurar `.clangd`

Crear archivo `.clangd` en la raíz del proyecto:

```yaml
CompileFlags:
  Compiler: /usr/bin/clang
  CompilationDatabase: out/build/x64-linux-configuration-debug # Ruta relativa al proyecto
  Add:
    - -std=c++20
    - -D_DEBUG

Index:
  Background: Build

Diagnostics:
  ClangTidy: {} # Objeto vacío, NO 'true'

Completion:
  AllScopes: true
```

### 3. Reglas Importantes

**NO incluir paths absolutos en `.clangd`**

❌ Mal (no portable):

```yaml
Add:
  - -I/home/usuario/proyectos/mi-proyecto/lib_core/include
```

✅ Bien (portable):

```yaml
CompileFlags:
  CompilationDatabase: out/build/x64-linux-configuration-debug
  Add:
    - -std=c++20
    - -D_DEBUG
```

**¿Por qué funciona?**

- `compile_commands.json` ya contiene todas las rutas de include absolutas generadas por CMake
- Es portable porque CMake regenera las rutas correctas en cualquier máquina
- clangd usa estas rutas para resolver headers

### 4. Reiniciar clangd

Después de modificar `.clangd`:

**Windsurf/VS Code:**

- `Ctrl+Shift+P` → `clangd: Restart language server`
- O `Developer: Reload Window`

## Solución de Problemas

### Error: "ClangTidy should be a dictionary"

❌ Incorrecto:

```yaml
Diagnostics:
  ClangTidy: true
```

✅ Correcto:

```yaml
Diagnostics:
  ClangTidy: {}
```

### Headers siguen sin encontrarse

1. Verificar que `compile_commands.json` existe y tiene entradas:

   ```bash
   cat out/build/compile_commands.json | grep -c '"file"'
   ```

2. Verificar que el archivo problemático está en la base de datos:

   ```bash
   cat out/build/compile_commands.json | grep "MiArchivo.cpp"
   ```

3. Recompilar el proyecto para regenerar la base de datos:
   ```bash
   cmake --build out/build
   ```

### Includes adicionales no cubiertos por CMake

Si necesitas includes que no están en la base de compilación:

**Opción 1: Rutas relativas (portable entre máquinas)**

```yaml
CompileFlags:
  CompilationDatabase: out/build/x64-linux-configuration-debug
  Add:
    - -std=c++20
    - -D_DEBUG
    - -Iinclude # Rutas relativas al directorio del proyecto
```

**Opción 2: Variables del editor (si el editor lo soporta)**

```yaml
CompileFlags:
  CompilationDatabase: out/build/x64-linux-configuration-debug
  Add:
    - -std=c++20
    - -D_DEBUG
    - -I${workspaceFolder}/some_extra_include # VS Code, Windsurf, etc.
```

Nota: `${workspaceFolder}` es una variable que expande a la ruta del proyecto. Funciona en VS Code y Windsurf, pero clangd nativo no la expande. Para máxima compatibilidad, usar rutas relativas.

## Estructura del Proyecto Ejemplo

```
proyecto/
├── .clangd                          # Configuración clangd
├── CMakeLists.txt                   # Root CMake
├── compile_commands.json -> out/build/.../compile_commands.json  # Symlink (opcional)
├── lib_core/
│   ├── include/core/http/
│   │   └── MojangClient.h
│   └── src/listener/
│       └── LoginListener.cpp       # Incluye <core/http/MojangClient.h>
└── out/build/x64-linux-configuration-debug/
    └── compile_commands.json        # Generado por CMake
```

## Comandos Útiles

```bash
# Regenerar base de datos de compilación
rm -rf out/build && cmake -B out/build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Ver entradas para un archivo específico
grep -A 5 'LoginListener.cpp' out/build/compile_commands.json

# Crear symlink (opcional, para compatibilidad con algunas herramientas)
ln -s out/build/compile_commands.json compile_commands.json
```

## Referencias

- [clangd documentation](https://clangd.llvm.org/config.html)
- [CMake compile_commands.json](https://cmake.org/cmake/help/latest/variable/CMAKE_EXPORT_COMPILE_COMMANDS.html)
