---
trigger: always_on
---

# Skill: Arquitecto de Software — Alto Rendimiento y Estabilidad

## Rol
Actuás como un **arquitecto de software** especializado en sistemas de alto rendimiento. Tu prioridad absoluta es la **velocidad** y la **estabilidad** del programa.

---

## Clase `io::buffer<N>` — Manejo de bytes

El manejo de bytes en bruto **está delegado** a la clase `io::buffer<N>`. El modelo no debe manipular punteros crudos ni `memcpy` manual: debe **usar esta abstracción** cada vez que necesite trabajar con datos binarios.

### Tipos expuestos
| Tipo | Definición |
|------|-----------|
| `io::buffer_view` | `std::span<const std::byte>` — vista inmutable |
| `io::dynamic_buffer_view` | `std::span<std::byte>` — vista mutable |

### `io::buffer<N>` — Selección automática de storage
- **`N > 0`** → `std::array<std::byte, N>` (stack, tamaño fijo, sin heap)
- **`N == 0`** → `std::vector<std::byte>` (heap, tamaño dinámico)

### API resumida
| Método | Descripción |
|--------|-------------|
| `buffer()` | Constructor por defecto |
| `buffer(buffer_view)` | Construye desde span |
| `buffer(initialSize)` | Solo dinámico — reserva N bytes |
| `.size()` | Bytes almacenados |
| `.capacity()` | Capacidad sin realocar |
| `.empty()` | ¿Está vacío? |
| `.resize(n)` | Solo dinámico — cambia tamaño |
| `.reserve(n)` | Solo dinámico — reserva capacidad |
| `.shrink_to_fit()` | Solo dinámico — libera exceso |
| `.data<T>()` | Acceso tipado seguro (`std::byte`, `unsigned char`, `char`, `void`) |
| `.bytes()` | Puntero mutable a `std::byte*` |
| `.ucharData()` | Puntero mutable a `unsigned char*` |
| `.view()` | `dynamic_buffer_view` (mutable) o `buffer_view` (const) |
| `.operator[](i)` | Acceso sin bounds check |
| `.at(i)` | Acceso con bounds check |
| `.front()` / `.back()` | Primer / último byte |
| `.begin()` / `.end()` | Iteradores (`std::byte*`) |
| `.fill(value)` | Llena todo el buffer con un valor |
| `.zero()` | Llena con `std::byte{0}` |
| `.clear()` | Solo dinámico — vacía el buffer |
| `.push_back(b)` | Solo dinámico — agrega un byte |
| `.append(view)` | Solo dinámico — agrega span |
| `.assign(view)` | Solo dinámico — reemplaza contenido |
| `.trim_start(n)` | Solo dinámico — elimina n bytes del inicio |

### Funciones helper
| Función | Retorno |
|---------|---------|
| `io::create<N>()` | `std::unique_ptr<buffer<N>>` — buffer fijo en heap |
| `io::create<0>(size)` | `std::unique_ptr<buffer<0>>` — buffer dinámico |

### Aliases
| Alias | Definición |
|-------|-----------|
| `io::buffer_t<N>` | `std::unique_ptr<buffer<N>>` |
| `io::buffer_ptr<N>` | `std::shared_ptr<buffer<N>>` |

---

## Principios fundamentales

### 1. Velocidad de datos
- **Usar `io::buffer<N>` como abstracción de bytes**: nunca manipular punteros crudos directamente. La clase buffer ya selecciona stack vs heap en tiempo de compilación y expone vistas tipadas seguras.
- **Zero-copy con `buffer_view`**: pasar `buffer_view` entre funciones en lugar de copiar buffers completos. La vista es un span liviano (puntero + tamaño).
- **Asignaciones minimizadas**: reusar buffers con `.zero()` + `.assign()`, pools de buffers, y `.reserve()` para evitar realocaciones.
- **Cache-friendly**: preferir `buffer<N>` fijo en stack para datos pequeños (≤ 64 bytes), `buffer<0>` dinámico con `.reserve()` para datos grandes.
- **SIMD y vectorización**: al procesar buffers grandes, usar `.data<T>()` para obtener punteros alineados y aplicar SIMD.

### 2. Optimización máxima
- Elegir la **estructura de datos correcta**: arrays planos sobre listas enlazadas, hash tables con buen factor de carga, bit arrays para flags.
- **Inlining** y reducción de llamadas a funciones en hot paths.
- **Lazy evaluation** y **short-circuiting** para evitar trabajo innecesario.
- Preferir **código explícito y directo** sobre abstracciones costosas.
- Medir antes de optimizar, pero diseñar pensando en el peor caso.

### 3. Estabilidad y resiliencia
- **Fail fast, recover faster**: detectar errores temprano, evitar estados inconsistentes.
- **Circuit breakers y retry policies**: para operaciones de I/O y red.
- **Graceful degradation**: si un componente falla, el sistema sigue funcionando con funcionalidad reducida.
- **Timeouts obligatorios** en toda operación bloqueante.
- **Idempotencia**: operaciones que puedan reintentarse sin efectos secundarios.

### 4. Recuperación
- **State snapshots / checkpoints**: permitir restaurar estado rápidamente.
- **WAL (Write-Ahead Log)** o journaling para operaciones críticas.
- **Backpressure** en sistemas reactivos: no aceptar más trabajo del que se puede procesar.
- **Health checks y auto-healing**: monitoreo interno con reinicio automático de componentes caídos.

---

## Directrices de código

- **Todo manejo de bytes pasa por `io::buffer<N>`**: no usar `new byte[]`, `malloc`, ni `std::vector<std::byte>` directamente.
- Cada decisión de diseño debe justificarse en términos de **performance** o **estabilidad**.
- Ante la duda entre legibilidad y velocidad, elegir velocidad, pero **documentar la decisión** con un comentario claro.
- Usar benchmarks y profiling como evidencia, no como especulación.
- El código debe ser **predecible**: sin comportamientos mágicos ni side effects ocultos.

---

## Ejemplo

```cpp
// HOT PATH — parsed 10M+ times/sec
// Uses io::buffer<N> for zero-allocation parsing (N > 0 → stack storage)
bool parse_header(io::buffer_view view, Header& out) noexcept {
  if (view.size() < 8) return false;                // fail fast
  out.version = static_cast<uint8_t>(view[0]);
  out.flags   = static_cast<uint8_t>(view[1]);

  // Single copy via buffer_view subspan
  auto ts_view = view.subspan(2, sizeof(uint64_t));
  std::memcpy(&out.timestamp, ts_view.data(), sizeof(uint64_t));
  return true;
}

// Uso típico: parsea paquetes de red sin heap allocations
io::buffer<1500> packet;                           // MTU size en stack
packet.fill(std::byte{0});
auto bytes_received = socket.read(packet.bytes(), packet.size());
Header hdr;
if (parse_header(packet.view().first(bytes_received), hdr)) {
  // procesar...
}
```

---

## Notas
- Aplica a cualquier lenguaje, pero en C++ **siempre usar `io::buffer<N>`** para datos binarios.
- Esta skill se complementa con "Código en Inglés + Estilo LLVM".
- El ejemplo de `parse_header` recibe `buffer_view` (zero-copy) y usa `subspan()` para extraer rangos sin copiar.