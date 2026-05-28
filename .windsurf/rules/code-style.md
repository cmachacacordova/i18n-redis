---
trigger: always_on
---

# Rule: Código en Inglés + Estilo LLVM

## Propósito
Esta regla establece el inglés como idioma obligatorio para la generación de código y documentación interna del código, y define el estilo de formateo por defecto (LLVM) con opción a consultar otros estilos.

---

## Regla 1 — Idioma del código

- **Código fuente**: siempre en **inglés**. Nombres de variables, funciones, clases, métodos, constantes, etc.
- **Documentación interna**: comentarios, docstrings, JSDoc, TSDoc, PHPDoc, y cualquier anotación dentro del código fuente debe escribirse en **inglés** y solamente documentar el código. No se aceptan comentarios en español dentro del código como comentarios innecesarios como la división o sección de un código.
- **Mensajes de commit**: en inglés.
- **Archivos README, CHANGELOG, CONTRIBUTING**: en inglés.
- Las explicaciones *alrededor* del código (en el chat) pueden seguir en español si el usuario lo prefiere, pero el código en sí y su documentación interna van en inglés.

---

## Regla 2 — Estilo de código

### Estilo por defecto: **LLVM**
- Sangría: **2 espacios**
- Llaves: en la **misma línea** (estilo K&R)
- `clang-format`: `BasedOnStyle: LLVM`

### Consulta previa
Antes de generar código, el agente **debe preguntar** qué estilo usar. Si el usuario no especifica, se usa **LLVM**.

Estilos disponibles:

| Estilo | Sangría | Columnas | Llaves |
|--------|---------|----------|--------|
| **LLVM** | 2 spaces | — | Misma línea (K&R) |
| **Google** | 2 spaces | 80 cols | Específico de Google |
| **Chromium** | 4 spaces | 80 cols | Similar a Google |
| **Mozilla** | 2 spaces | — | Ligera variación K&R |
| **WebKit** | 4 spaces | — | Llave abierta antes de funciones |
| **Microsoft** | 4 spaces | — | Llaves independientes (Allman) |

---

## Ejemplos

### ✅ Correcto (inglés + LLVM)

```cpp
// Calculate the factorial of a given number
int factorial(int n) {
  if (n <= 1)
    return 1;
  return n * factorial(n - 1);
}
```

### ❌ Incorrecto (español en código)

```cpp
// Calcula el factorial de un número dado
int factorial(int n) {
```

---

## Notas
- Para formateo automático se recomienda `clang-format` con el estilo correspondiente.
- Esta regla aplica a todos los lenguajes: C, C++, Python, JavaScript, TypeScript, Rust, Go, Java, etc.
