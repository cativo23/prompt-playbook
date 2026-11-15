# Data Model: Versión en español

No hay datos dinámicos. Lo que se "modela" es contenido estático y el glosario que mantiene la traducción consistente.

## Entidades

### Página
| Campo | EN | ES |
|---|---|---|
| Archivo | `index.html` | `es/index.html` |
| URL | `https://nospoon.cativo.dev/` | `https://nospoon.cativo.dev/es/` |
| `lang` | `en` | `es-419` |
| Fuente del texto | `content/final.md` | `content/final.es.md` |

**Regla:** las dos páginas tienen las mismas secciones, los mismos `id`, los mismos enlaces de fuente y las mismas cifras.

### Sección
`id` compartido (no se traduce) → número hex → rótulo.

| id | hex | EN (rótulo) | ES (rótulo) |
|---|---|---|---|
| why | 0x00 | THE PHYSICS | LA FÍSICA |
| formula | 0x01 | THE FORMULA | LA FÓRMULA |
| examples | 0x02 | BEFORE / AFTER | ANTES / DESPUÉS |
| agents | 0x03 | AGENTS | AGENTES |
| context | 0x04 | CONTEXT HYGIENE | HIGIENE DE CONTEXTO |
| output | 0x05 | OUTPUT | SALIDA |
| pocket | 0x06 | POCKET PROMPTS | PROMPTS DE BOLSILLO |
| settings | 0x07 | SETTINGS | AJUSTES |
| field | 0x08 | FIELD NOTES | NOTAS DE CAMPO |

Los rótulos en español son una propuesta. Se ajustan en la traducción si el texto de la sección pide otro, sin cambiar los ids.

### Enlace de fuente
`href` idéntico en las dos versiones. Lo que va entre corchetes (por ejemplo, `[best-practices]`) es el nombre de la página de documentación y no se traduce.

## Glosario (contrato de traducción)

| EN | ES | Nota |
|---|---|---|
| prompt | prompt | Se usa así en la región |
| token | token | |
| context / context window | contexto / ventana de contexto | |
| agent / subagent | agente / subagente | |
| agent team | equipo de agentes | |
| Advice | Consejo | Rótulo fijo (FR-008), siempre igual |
| field notes | notas de campo | |
| case study | caso de estudio | |
| cache / cache hit | caché / acierto de caché | "la caché" |
| compact (verb) | compactar | El comando `/compact` no se traduce |
| clear (verb) | limpiar | El comando `/clear` no se traduce |
| weekly limit | límite semanal | |
| usage | uso | |
| turn | turno | |
| delegate | delegar | |
| scope | alcance | |
| settings | ajustes / configuración | Las claves de config no se traducen |
| pocket prompts | prompts de bolsillo | |
| copy / copied (botón) | copiar / copiado | |
| follow the white rabbit | sigue al conejo blanco | |
| there is no spoon | no hay cuchara | |
| Free your context | Libera tu contexto | Titular "Libera" + palabras animadas: tu contexto. / tu límite semanal. / a tus agentes. (el posesivo va en la palabra animada para que "agentes" concuerde) |
| WHAT / LIMIT / DONE / HOW | QUÉ / LÍMITE / LISTO / CÓMO | Claves de la fórmula, iguales en 0x01, 0x06 e índice |
| teammate | integrante | |
| lead (session) | líder | |
| goal check-ins | chequeos de objetivo | |
| RULE (rótulo CSS) | REGLA | |

**Prohibido (FR-005):** vosotros/os/vuestro, voseo (tenés, podés, querés, hacé, mirá), "ordenador", "móvil", "vale" como muletilla, "fichero".
