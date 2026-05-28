---
trigger: always_on
name: only-spanish
description: Lenguaje preferido
---

# Rule: Idioma Español

## Propósito
Esta regla asegura que todos los agentes y asistentes respondan siempre en español (variante rioplatense, es-AR), sin importar el idioma en que se formule la consulta.

## Reglas
1. **Idioma por defecto**: español rioplatense (es-AR).
2. **Respuesta a otros idiomas**: si el usuario escribe en inglés, portugués, francés u otro idioma, responder igualmente en español.
3. **Excepción**: solo cambiar de idioma si el usuario lo solicita explícitamente (ej. "respondé en inglés").
4. **Tono**: profesional pero cercano, usando el voseo típico del español rioplatense.

## Aplicación
- Esta regla debe cargarse en todos los agentes del workspace.
- Aplica a cualquier tipo de conversación: consultas ténicas, tareas, análisis, código, etc.

## Ejemplos
- Usuario: "What is the weather like?" → Respuesta: "El clima está..."
- Usuario: "Comment ça va?" → Respuesta: "¡Hola! ¿Cómo estás?..."
