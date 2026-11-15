# Prompt Playbook

> Vol. 0x01 :: Núm. 0x01 :: Philes 0x00-0x08 :: guía de campo para agentes
> Cada dato lleva un enlace a su fuente. Las líneas marcadas como "Consejo" son reglas prácticas, no hechos. Las fuentes son la documentación oficial, en inglés.
> 0x08 es distinta: son notas de campo de una semana medida de un desarrollador, no documentación.
> Los valores por defecto que dependen de la versión o del plan se revisaron el 2026-11-14 y pueden cambiar.

Libera tu contexto. El agente hace lo que pides, no lo que quieres decir. Los prompts vagos tienden a volverse contextos grandes, y un contexto grande consume uso en cada turno. Este zine es el arreglo.

Índice:
- 0x00 Por qué los prompts gastan tokens
- 0x01 La fórmula (QUÉ / LÍMITE / LISTO / CÓMO)
- 0x02 Antes / después
- 0x03 Prompts para agentes
- 0x04 Higiene de contexto
- 0x05 Pedir la salida que quieres
- 0x06 Prompts de bolsillo
- 0x07 Ajustes que te protegen
- 0x08 Notas de campo: una semana medida

---

## 0x00 :: LA FÍSICA: Cada turno vuelve a leerlo todo

El modelo no guarda memoria entre solicitudes, así que en cada turno el agente reenvía el contexto completo: el prompt del sistema, el contexto del proyecto, cada mensaje anterior y cada resultado de herramienta, más tu mensaje nuevo. La caché solo evita reprocesar el prefijo que no cambió, que se relee a una tarifa de caché más barata. El contexto se sigue cargando y cobrando en cada turno. [prompt-caching](https://code.claude.com/docs/en/prompt-caching)

El costo crece con el tamaño del contexto, y el uso de herramientas lo multiplica: cada llamada a una herramienta dispara otra solicitud que lleva todo el historial. Aun con caché, una pregunta de una línea en una sesión abierta todo el día sigue consumiendo uso por toda la conversación. [costs](https://code.claude.com/docs/en/costs)

### Cómo funciona la caché

- La coincidencia es de prefijo exacto. Un cambio en cualquier parte del prefijo obliga a recalcular todo lo que viene después; no hay caché por archivo ni por segmento. El contenido que casi no cambia (prompt del sistema, definiciones de herramientas, contexto del proyecto) va primero y la conversación al final, así que agregar es barato y modificar contenido temprano es caro. [prompt-caching](https://code.claude.com/docs/en/prompt-caching)
- Los prefijos en caché expiran tras un periodo de inactividad, y cada acierto de caché reinicia el temporizador. El primer mensaje después de una pausa más larga que la vida de la caché reprocesa el contexto completo (más lento y más costoso). [prompt-caching](https://code.claude.com/docs/en/prompt-caching)
- La API ofrece un TTL de 5 minutos y otro de 1 hora. El de 1 hora cobra una tarifa más alta por escribir en la caché, así que sirve cuando dejas una sesión inactiva y vuelves, y cuesta más en ráfagas cortas que nunca llegan a cinco minutos de inactividad. [prompt-caching](https://code.claude.com/docs/en/prompt-caching)
- El TTL por defecto en Claude Code depende de cómo pagas. La conversación principal recibe 1 hora solo con una suscripción de Claude dentro del uso incluido en el plan; con créditos de uso, una clave de API o un proveedor de nube recibe 5 minutos. Los subagentes, los workflows, la compactación y los títulos de sesión usan 5 minutos por defecto, salvo un conjunto pequeño de solicitudes auxiliares controladas por el servidor en una suscripción. Los controles de TTL requieren v2.1.242+. Los valores por defecto pueden cambiar, así que tómalo como cierto al 2026-11-14. [prompt-caching](https://code.claude.com/docs/en/prompt-caching)

### Dónde se filtra

Las sesiones inactivas igual pueden consumir uso:

| Fuga | Por qué daña | Fuente |
|---|---|---|
| tareas programadas de la sesión | se disparan en su intervalo con la sesión inactiva y envían todo el contexto cada vez | [costs](https://code.claude.com/docs/en/costs) |
| mensajes de otras sesiones | se entregan como un turno nuevo cuando la sesión está inactiva | [costs](https://code.claude.com/docs/en/costs) |
| chequeos de objetivo | pueden iniciar turnos inactivos (como máximo tres por objetivo entre tus prompts) | [costs](https://code.claude.com/docs/en/costs) |
| resumen de sesión y compactación inactiva | pueden gastar tokens mientras no estás; la compactación inactiva aplica a una conversación con el TTL de una hora | [costs](https://code.claude.com/docs/en/costs), [prompt-caching](https://code.claude.com/docs/en/prompt-caching) |


---

## 0x01 :: LA FÓRMULA: Cuatro piezas, una línea cada una

Un prompt no necesita ser largo. Consejo: haz que responda cuatro preguntas.

| Pieza | Responde | Respaldo |
|---|---|---|
| QUÉ | objetivo, más el archivo o área y el síntoma | Nombra el archivo o el área, describe el síntoma y di desde el principio cómo se ve "arreglado". Esto le da al agente información que no puede sacar del repo y por lo general ahorra una ronda de correcciones. [best-practices](https://code.claude.com/docs/en/best-practices) |
| LÍMITE | alcance, en cualquier dirección | El agente tiende a leer una petición de forma conservadora y a construir lo más pequeño que la satisfaga. Si quieres casos límite, estados vacíos y de error o la continuación natural, dilo (la documentación usa la frase "be ambitious"). [best-practices](https://code.claude.com/docs/en/best-practices) Consejo: el alcance es tuyo, así que dilo en los dos sentidos. |
| LISTO | una verificación que devuelve pasa o falla | Sin una verificación, lo único que tiene el agente para guiarse es que "parece terminado", y en la práctica tú te conviertes en la suite de pruebas. Ejemplos de verificaciones: pruebas, código de salida del build, linter, diff de fixtures, captura de pantalla vs maqueta. [best-practices](https://code.claude.com/docs/en/best-practices) |
| CÓMO | preferencias, modo plan, razones | Si te importa cuál de dos enfoques razonables elige el agente, dilo, porque no se puede leer en el código. [best-practices](https://code.claude.com/docs/en/best-practices) Explica la razón detrás de una instrucción, no solo la regla; el contexto o la motivación ayuda al modelo a dar resultados más enfocados. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) |

> REGLA (consejo): termina cada prompt de trabajo con la verificación que prueba que está terminado ("Listo cuando ___").

### Verificaciones básicas

- Prueba del colega: si un colega con contexto mínimo se confundiría con tu prompt, el modelo también. Usa listas numeradas o viñetas cuando importa el orden de los pasos o que no falte ninguno. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- Pide evidencia: pide el comando ejecutado y su salida, o una captura de pantalla, no solo "todas las pruebas pasan". En una sesión que no estabas mirando, es la única evidencia que tienes. [best-practices](https://code.claude.com/docs/en/best-practices)
- Planear antes de actuar: el modo plan deja que el agente lea archivos y proponga un plan sin editar nada hasta que lo apruebes. Entra con `claude --permission-mode plan` o con Shift+Tab a mitad de la sesión. Úsalo para cambios que quieras revisar antes de que toquen el disco. [common-workflows](https://code.claude.com/docs/en/common-workflows)
- Corrige el rumbo temprano: mira el primer minuto y presiona Esc en cuanto el agente se desvíe. Esc detiene a mitad de acción y conserva todo hasta ese punto; `/rewind` (o Esc dos veces con el prompt vacío) abre un menú para devolver el código, la conversación o ambos a un prompt anterior. [best-practices](https://code.claude.com/docs/en/best-practices)
- Explorar es distinto: los prompts vagos sirven para explorar (p. ej. "¿qué mejorarías en este archivo?"). Corregirás un poco más sobre la marcha. Pon la especificidad donde ya sabes lo que quieres. [best-practices](https://code.claude.com/docs/en/best-practices)

---

## 0x02 :: ANTES / DESPUÉS: Misma intención, menos rondas de corrección

**PATCH 01 :: sin síntoma, sin ubicación, sin verificación**

```diff
- arregla el bug del login
+ los usuarios reportan que el login falla después de que expira la sesión. revisa
+ la renovación del token en src/auth/, escribe una prueba que falle y reproduzca
+ el error, y luego corrígelo
```
Agregado: síntoma, ubicación, una prueba que falla y reproduce el error, y luego la corrección. [best-practices](https://code.claude.com/docs/en/best-practices)

**PATCH 02 :: sin patrón, sin restricción**

```diff
- agrega un widget de calendario
+ sigue el patrón de ExistingWidget.php y crea un widget de calendario que permita
+ elegir un mes y pasar de un año a otro. sin librerías nuevas
```
Agregado: un patrón existente que copiar y una restricción. (El ejemplo de la documentación usa otro nombre de archivo.) [best-practices](https://code.claude.com/docs/en/best-practices)

**PATCH 03 :: describir la cosa en vez de entregarla**

Referencia un archivo con `@path`, pega capturas de pantalla de diseños o errores, y canaliza la salida de comandos hacia el prompt. El ejemplo de la documentación es `cat error.log | claude -p "what's going on here"`. [best-practices](https://code.claude.com/docs/en/best-practices)

**PATCH 04 :: sugerencias cuando querías acción**

```diff
- ¿puedes sugerir algunos cambios a la lógica de reintentos?
+ cambia la lógica de reintentos para que aplique backoff después del tercer fallo
```
Una frase como "¿puedes sugerir algunos cambios?" puede producir sugerencias en vez de ediciones, así que di "cambia esto" cuando quieras que se haga el cambio. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)


---

## 0x03 :: AGENTES: Empieza con poco, delega a propósito

### Subagente o equipo

Empieza con un subagente, no con un equipo de agentes. Los subagentes trabajan dentro de una sola sesión y le devuelven un resultado a quien los llamó. Los integrantes de un equipo son sesiones separadas y totalmente independientes que se mandan mensajes directamente entre sí. Los subagentes cuestan menos porque sus resultados vuelven resumidos al contexto principal; los equipos cuestan más porque cada integrante es su propia instancia de Claude. Usa subagentes para trabajadores enfocados que reportan de vuelta, y equipos cuando los trabajadores necesitan compartir hallazgos y cuestionarse entre ellos. [agent-teams](https://code.claude.com/docs/en/agent-teams)

### Costo

- Los equipos cuestan bastante más que una sola sesión, y el uso crece con la cantidad de integrantes activos y con el tiempo que corre cada uno. La guía de costos de Anthropic dice que los equipos de agentes usan aproximadamente 7x más tokens que las sesiones estándar cuando los integrantes corren en plan mode. [costs](https://code.claude.com/docs/en/costs) Para tareas rutinarias, una sola sesión es más económica. [agent-teams](https://code.claude.com/docs/en/agent-teams)
- El sistema de investigación multiagente de Anthropic midió que los agentes usan cerca de 4x más tokens que un chat, y los sistemas multiagente cerca de 15x más. El uso de tokens por sí solo explicó el 80% de la varianza en BrowseComp. Reserva las configuraciones multiagente para tareas cuyo valor sea lo bastante alto como para pagar el mayor rendimiento. [Anthropic engineering](https://www.anthropic.com/engineering/multi-agent-research-system)
- Las solicitudes de los subagentes igual consumen tu uso. [costs](https://code.claude.com/docs/en/costs)

### Los subagentes ahorran contexto

Delega las operaciones verbosas (correr pruebas, traer documentación, procesar logs) para que la salida ruidosa se quede en el contexto del subagente y solo vuelva un resumen. Aun así, muchos subagentes que devuelven resultados detallados pueden consumir bastante contexto de la conversación principal, y cada subagente gasta sus propios tokens. [sub-agents](https://code.claude.com/docs/en/sub-agents) Consejo: pide resúmenes concisos.

### Cómo escribir el prompt de delegación

- Todo trabajador delegado necesita un objetivo, un formato de salida, indicaciones sobre herramientas y fuentes, y límites claros para la tarea. Sin descripciones detalladas de la tarea, Anthropic encontró que los agentes duplican trabajo, dejan huecos o no logran encontrar la información necesaria. [Anthropic engineering](https://www.anthropic.com/engineering/multi-agent-research-system)
- Un integrante carga el mismo contexto de proyecto que una sesión normal (CLAUDE.md, servidores MCP, skills) más el prompt de lanzamiento, pero el historial de conversación del líder no se transfiere. [agent-teams](https://code.claude.com/docs/en/agent-teams) Todo lo que va en el prompt de lanzamiento se suma a su contexto desde el inicio. [costs](https://code.claude.com/docs/en/costs) Consejo: incluye los detalles de la tarea que necesita (alcance, archivos, restricciones, salida esperada) y poco más.
- Dimensiona las tareas como unidades autocontenidas con un entregable claro, como una función, un archivo de pruebas o una revisión. Si son muy chicas, el costo de coordinación supera el beneficio; si son muy grandes, los integrantes trabajan demasiado tiempo sin puntos de control y sube el riesgo de esfuerzo desperdiciado. La documentación sugiere 5-6 tareas por integrante. Dale a cada integrante un conjunto distinto de archivos, porque dos integrantes que editan el mismo archivo terminan sobrescribiéndose. [agent-teams](https://code.claude.com/docs/en/agent-teams)
- El esfuerzo debe escalar con la tarea. En el sistema de investigación de Anthropic: buscar un dato simple necesita 1 agente con 3-10 llamadas a herramientas, las comparaciones directas 2-4 subagentes con 10-15 llamadas cada uno, y la investigación compleja más de 10 subagentes. Son pautas de ese sistema, no una regla de Claude Code. [Anthropic engineering](https://www.anthropic.com/engineering/multi-agent-research-system)

### Mantén los equipos chicos y supervisados

- Empieza con 3-5 integrantes para la mayoría de los flujos de trabajo. El costo en tokens crece de forma lineal con el tamaño del equipo, mientras la sobrecarga de coordinación aumenta y los beneficios disminuyen, así que tres integrantes enfocados suelen rendir más que cinco dispersos. Escala solo cuando al trabajo le sirva que los integrantes trabajen al mismo tiempo. [agent-teams](https://code.claude.com/docs/en/agent-teams)
- Los equipos funcionan mejor si empiezas con tareas de investigación y revisión que tengan límites claros y no requieran escribir código, como revisar un PR, investigar una biblioteca o investigar un bug. Supervisa y corrige el rumbo en vez de dejar al equipo sin atención, porque un equipo sin supervisión aumenta el riesgo de esfuerzo desperdiciado. Si el líder empieza a implementar en vez de esperar, dile que espere a que los integrantes terminen. [agent-teams](https://code.claude.com/docs/en/agent-teams)
- Cierra a los integrantes cuando terminen su trabajo; cada integrante activo sigue consumiendo tokens hasta que sale o termina la sesión. Pídele al líder que cierre a uno por su nombre. El integrante puede aprobar o rechazar con una explicación, y primero termina su solicitud o llamada a herramienta en curso, así que el cierre puede tardar. La configuración del equipo se elimina cuando termina la sesión, pero el directorio de la lista de tareas queda en disco. [costs](https://code.claude.com/docs/en/costs), [agent-teams](https://code.claude.com/docs/en/agent-teams)
- Los equipos de agentes son experimentales y vienen desactivados por defecto (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` los activa). Una vez activados, un subagente que Claude nombra se lanza como integrante, así que puede formarse un equipo aunque no hayas pedido uno. Si pones la variable en `0`, los subagentes nombrados vuelven a lanzarse como subagentes normales. Una fuente de configuración de mayor precedencia o la configuración administrada aún puede activarlos. [agent-teams](https://code.claude.com/docs/en/agent-teams)

### Elige un modelo más chico para el trabajo delegado

La guía de costos de Anthropic dice que uses Sonnet para los integrantes y que especifiques `model: haiku` para las tareas simples de subagentes. Los subagentes que heredan el modelo de tu sesión lo siguen, así que cambiar la sesión principal a Opus también se aplica a todos los subagentes que heredan. Puedes indicar el modelo en el prompt de lanzamiento (por ejemplo, "Usa Sonnet para cada integrante"). [costs](https://code.claude.com/docs/en/costs), [agent-teams](https://code.claude.com/docs/en/agent-teams)

### Cuándo NO usar agentes ni equipos

Para tareas secuenciales, ediciones en el mismo archivo y trabajo con muchas dependencias, una sola sesión o subagentes son más efectivos. Las idas y vueltas frecuentes, el refinamiento iterativo, las fases que comparten mucho contexto, los cambios puntuales y el trabajo sensible a la latencia pertenecen a la conversación principal. [agent-teams](https://code.claude.com/docs/en/agent-teams), [sub-agents](https://code.claude.com/docs/en/sub-agents) La publicación de investigación de Anthropic también señala que los dominios donde todos los agentes deben compartir el mismo contexto, o con muchas dependencias entre agentes, hoy encajan mal con los sistemas multiagente, y que la mayoría de las tareas de programación tienen menos tareas realmente paralelizables que la investigación. [Anthropic engineering](https://www.anthropic.com/engineering/multi-agent-research-system)

### Lista de verificación previa (consejo)

1. ¿El entregable cabe en una oración? Si necesitas "y además...", probablemente son dos trabajos.
2. ¿Dijiste qué leer y cómo debe verse la salida?
3. ¿Hay una meta que el agente pueda verificar?
4. ¿De verdad necesitas un agente? Una sola sesión es lo predeterminado para el trabajo rutinario.

## 0x04 :: HIGIENE DE CONTEXTO: Limpia entre tareas, compacta a propósito

| Comando | Qué hace | Costo |
|---|---|---|
| `/clear` | contexto nuevo para una tarea sin relación | no cuesta nada por sí mismo [costs](https://code.claude.com/docs/en/costs) |
| `/compact` | resume el historial | envía una solicitud de resumen aparte que incluye el historial que se va a resumir [prompt-caching](https://code.claude.com/docs/en/prompt-caching) |
| `/rewind` | trunca hasta un turno anterior | vuelve a un prefijo que ya está en caché, en vez de construir uno nuevo [prompt-caching](https://code.claude.com/docs/en/prompt-caching) |

- Limpia entre tareas sin relación: el contexto viejo cuesta tokens en cada mensaje posterior. Ejecuta `/rename` primero para poder encontrar la sesión y retomarla después con `/resume`. [costs](https://code.claude.com/docs/en/costs)
- Compactar tiene un precio: mientras la caché está caliente, la solicitud lee sobre todo el prefijo en caché (barato). Tras una pausa más larga que el TTL, reprocesa todo el historial sin caché, así que compactar una sesión vieja que se retomó es el caso más caro. El turno posterior a la compactación reconstruye la caché solo para el historial, que ahora es mucho más corto. [prompt-caching](https://code.claude.com/docs/en/prompt-caching)
- Compacta en los cortes naturales (entre tareas) en vez de dejar que la autocompactación se dispare a mitad de tarea. Si seguiste un camino que quieres abandonar por completo, usa `/rewind` para volver a un turno anterior. [prompt-caching](https://code.claude.com/docs/en/prompt-caching)
- Controla qué sobrevive: ejecuta `/compact` con instrucciones (p. ej. `/compact focus on the auth bug fix`), o agrega una sección "Compact instructions" al CLAUDE.md del proyecto. [context-window](https://code.claude.com/docs/en/context-window.md), [costs](https://code.claude.com/docs/en/costs)
- Ten claro qué se reinyecta: tras la compactación, el CLAUDE.md de la raíz del proyecto, las reglas sin alcance y la memoria automática se reinyectan desde el disco. Las reglas con frontmatter `paths:` y los CLAUDE.md anidados se resumen junto con la conversación y solo se recargan bajo demanda. Pon las reglas que deben sobrevivir en el CLAUDE.md de la raíz (o quita el frontmatter `paths:`). [context-window](https://code.claude.com/docs/en/context-window.md)

### No rompas la caché a mitad de tarea

Evita los cambios a mitad de tarea que invalidan la caché: cambiar de modelo (cada modelo tiene su propia caché), activar o desactivar el modo rápido, conectar o quitar a propósito un servidor MCP (cuando tool search no difiere sus herramientas), denegar una herramienta completa cuando tool search está desactivado, acumular muchas imágenes y actualizar la herramienta. Con tool search activo (el valor por defecto en los modelos compatibles), los casos de MCP y de reglas de denegación no alteran la caché. Elige modelo y esfuerzo al inicio de la sesión. Editar CLAUDE.md a mitad de sesión no invalida la caché, pero tampoco se aplica hasta `/clear`, `/compact` o un reinicio. [prompt-caching](https://code.claude.com/docs/en/prompt-caching)

### Mantén el contexto pequeño desde el origen

- Delega las operaciones verbosas (pruebas, descarga de documentación, procesamiento de logs) a subagentes para que solo regrese un resumen.
- Usa hooks para preprocesar la salida ruidosa (p. ej. recorta la salida de las pruebas a las últimas 100 líneas).
- Prefiere las herramientas CLI (`gh`, `aws`, `gcloud`) sobre los servidores MCP cuando existan.
- Desactiva los servidores MCP que no uses desde `/mcp`.
- Procura mantener CLAUDE.md por debajo de 200 líneas y mueve las instrucciones propias de un flujo de trabajo a skills bajo demanda.

Los cinco: [costs](https://code.claude.com/docs/en/costs). La cifra de 200 líneas es la recomendación "aim to" de la documentación.

### Inspecciona antes de adivinar

- `/context` muestra un desglose en vivo del contexto por categoría, con sugerencias de optimización, incluidos los archivos CLAUDE.md y de memoria automática que se cargaron. [context-window](https://code.claude.com/docs/en/context-window.md)
- `/usage` muestra los totales de tokens de la sesión. En los planes Pro, Max, Ultra, Team y Enterprise también atribuye el uso reciente a skills, subagentes, plugins y servidores MCP, con recomendaciones. Tras la primera respuesta agrega una línea "Prompt cache (main)" con la proporción de aciertos de caché, los fallos y si la caché está caliente o fría (v2.1.251+); puede nombrar la causa probable del último fallo (v2.1.260+). [costs](https://code.claude.com/docs/en/costs)


---

## 0x05 :: SALIDA: Pide la forma que quieres

Sé específico sobre la salida que quieres: indica el formato y las restricciones de forma explícita. Si quieres más que la tarea básica, pídelo explícitamente en vez de confiar en que el modelo lo infiera de un prompt vago. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

### Formato

- Di lo que quieres, no lo que no quieres: usa "Your response should be composed of smoothly flowing prose paragraphs" en lugar de "Do not use markdown in your response". [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- El estilo de tu prompt puede influir en el estilo de la respuesta: si el formato sigue sin responder, intenta que el estilo del prompt se parezca al de la salida que quieres; quitar el markdown de tu prompt puede reducir la cantidad de markdown en la salida. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- Usa etiquetas XML para separar instrucciones, contexto y entrada: ayudan a Claude a interpretar sin ambigüedad los prompts complejos, sobre todo cuando un prompt mezcla instrucciones, contexto, ejemplos y entradas variables. Envuelve cada tipo en su propia etiqueta (por ejemplo `<instructions>`, `<context>`, `<input>`). [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- Evita los preámbulos con una instrucción directa: `Respond directly without preamble. Do not start with phrases like "Here is...", "Based on...", etc.` La documentación enumera alternativas (salida dentro de etiquetas XML, salidas estructuradas o llamadas a herramientas) y dice que se elimine el preámbulo ocasional en el posprocesamiento. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

### Longitud (las muestras de la documentación son para Claude Opus 5)

- Pide la longitud; no bajes el esfuerzo para conseguirla: el esfuerzo controla cuánto piensa el modelo, no cuánto dice. Bajar el esfuerzo puede reducir el pensamiento sin acortar de forma fiable la respuesta visible. Muestra oficial: *"Keep responses focused, brief, and concise. Keep disclaimers and caveats short, and spend most of the response on the main answer. When asked to explain something, give a high-level summary unless an in-depth explanation is specifically requested."* En un prompt de sistema largo, acompáñala con un recordatorio corto cerca del final. [Opus 5 guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)
- Calibra por separado los entregables escritos: los archivos que se escriben en disco suelen salir más largos que con modelos anteriores. Muestra: *"Match the length of written documents to what the task needs: cover the substance, but do not pad with filler sections, redundant summaries, or boilerplate."* [Opus 5 guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)
- Da forma al reporte de fin de tarea: muestra: *"When you finish, lead with the outcome: your first sentence should answer 'what happened' or 'what did you find,' with supporting detail after it for readers who want it."* Los ejemplos positivos del estilo de comunicación que quieres tienden a ser más efectivos que las instrucciones sobre lo que no hay que hacer. [Opus 5 guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)

### Preguntas y decisiones

- Limita las preguntas aclaratorias diciendo cuándo se permite una: muestra de control de alcance para Opus 5: *"Deliver what was asked, at the scope intended. Make routine judgment calls yourself, and check in only when different readings of the request would lead to materially different work. If the request seems mistaken or a better approach exists, say so in a sentence and continue with the task as asked rather than quietly narrowing, widening, or transforming it."* [Opus 5 guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)
- Invita a las preguntas a propósito: si no has definido bien lo que quieres, pídele a Claude que te entreviste hasta poder escribir la especificación, y que la guarde en un archivo. Claude vuelve con preguntas de opción múltiple sobre las partes que no has definido. Luego construye a partir de la especificación en una sesión nueva, para que la construcción empiece con contexto limpio y una definición de terminado por escrito. [best-practices](https://code.claude.com/docs/en/best-practices)
- Recomendaciones sin ediciones: los modelos más recientes de Claude siguen las instrucciones con precisión, así que "¿puedes sugerir algunos cambios?" puede recibir sugerencias en lugar de ediciones. Para un modo conservador, la documentación muestra un fragmento de prompt de sistema que dice que no se cambien archivos salvo instrucción clara, y que cuando la intención es ambigua el modelo debe optar por informar, investigar y recomendar en lugar de actuar. Pide la acción de forma explícita cuando quieras ediciones. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)
- Ten cuidado al limitar la salida de las revisiones: la guía de Opus 5 dice que si un prompt de revisión pide "only report high-severity issues" o "be conservative", el modelo podría seguirlo al pie de la letra y reportar menos. Pídele que reporte todo y filtra en una pasada aparte. [Opus 5 guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)

### Salida legible por máquinas (API)

- Las salidas estructuradas restringen la respuesta a un esquema JSON mediante `output_config.format` con el tipo `json_schema` (decodificación restringida). La documentación indica "Always valid: No JSON parsing errors" y "Type safe: Guaranteed field types and required fields". Salvedades: los rechazos (`stop_reason` "refusal") y los cortes por `max_tokens` pueden producir una salida que no coincide con el esquema, y los valores de enum pueden variar en mayúsculas, así que compáralos sin distinguir mayúsculas de minúsculas. Para clasificación, usa un campo enum con tus etiquetas válidas (mediante herramientas o salidas estructuradas). [structured outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs)
- No se admiten: esquemas recursivos, restricciones numéricas (minimum/maximum), restricciones de longitud de cadena y `additionalProperties` distinto de false (todos los objetos deben fijarlo en false). La primera solicitud con un esquema nuevo tiene latencia extra mientras se compila la gramática; las gramáticas compiladas se guardan en caché durante 24 horas desde el último uso. [structured outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs)
- Si no puedes usar salidas estructuradas, prueba primero solo con el prompt: los modelos nuevos pueden ajustarse de forma fiable a esquemas complejos si se les pide, sobre todo si se implementa con reintentos. Rellenar de antemano el turno del asistente (prefill) ya no se admite en Claude 4.6 y modelos posteriores (las solicitudes devuelven un error 400), así que forzar el formato con prefill requiere otro enfoque. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)


---

## 0x06 :: PROMPTS DE BOLSILLO: Copia, completa, envía

Reemplaza lo que está entre `<corchetes angulares>`. Nada más cambia.

**0x06.1 :: TAREA ACOTADA** (Consejo: la forma QUÉ / LÍMITE / LISTO de 0x01)

```
Objetivo: <una frase, con el archivo o el área y el síntoma>
Solo toca: <archivo o carpeta>
Listo cuando: <una verificación que dé pasa o falla: test / build / linter>
Muéstrame: el comando que ejecutaste y su salida.
```
Por qué: nombra el área y el síntoma, di cómo se ve lo arreglado y pide evidencia. [best-practices](https://code.claude.com/docs/en/best-practices)

**0x06.2 :: CICLO DE VERIFICACIÓN**

```
Después del cambio, ejecuta <los tests de autenticación> y sigue hasta que pasen.
```
Sirve para cualquier tarea, sin preparación. [best-practices](https://code.claude.com/docs/en/best-practices)

**0x06.3 :: AUTOVERIFICACIÓN** (agrégala al final de cualquier prompt)

```
Antes de terminar, verifica tu respuesta contra <criterios de prueba>.
```
La documentación dice que esto detecta errores de forma confiable, sobre todo en código y matemáticas. Salvedad: Claude Opus 5 verifica bien su propio trabajo sin que se lo pidan, y las instrucciones de verificación heredadas pueden causar sobreverificación en ese modelo (más tokens y más latencia); la documentación dice que se quiten en ese modelo. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

**0x06.4 :: PLANEAR ANTES DE ACTUAR**

```
Objetivo: <una frase>
Lee los archivos relevantes y propón un plan. No edites nada hasta que yo lo apruebe.
```
O empieza en modo plan: `claude --permission-mode plan`. [common-workflows](https://code.claude.com/docs/en/common-workflows)

**0x06.5 :: SIN SOBREINGENIERÍA** (antepónla a cualquier prompt)

```
Haz solo los cambios que se piden directamente. No agregues funciones, refactors ni
"mejoras" más allá de lo pedido. No agregues docstrings, comentarios ni anotaciones
de tipo al código que no cambiaste. No agregues manejo de errores, alternativas de
respaldo ni validación para escenarios que no pueden ocurrir. No crees helpers ni
abstracciones para operaciones de una sola vez. No agregues configurabilidad extra.
```
Adaptado del prompt de ejemplo de la documentación. La documentación señala que Claude Opus 4.5 y 4.6 tienden a sobrediseñar, así que sirve más si ves ese comportamiento. [prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)

**0x06.6 :: SÉ AMBICIOSO** (la dirección contraria)

```
Sé ambicioso: <estados vacíos y de error, el flujo de guardado conectado, navegación con teclado>.
```
El agente tiende a construir lo mínimo que satisface una petición, así que pide más de forma explícita. [best-practices](https://code.claude.com/docs/en/best-practices)

**0x06.7 :: ENTREVISTA, LUEGO ESPECIFICACIÓN**

```
Entrévistame hasta que puedas escribir la especificación, y luego escríbela en SPEC.md.
```
Después construye a partir de SPEC.md en una sesión nueva. [best-practices](https://code.claude.com/docs/en/best-practices)

**0x06.8 :: PROMPT PARA LANZAR UN SUBAGENTE** (Consejo: forma tomada de la guía de delegación de la documentación en 0x03)

```
Objetivo: <un entregable, p. ej. revisar <ruta> por <aspecto>>
Alcance: solo <archivos>; no edites <archivos>.
Herramientas/fuentes: <qué usar o leer>.
Salida: <formato>, solo un resumen conciso.
Modelo: <Sonnet>.
```
Por qué: objetivo, formato de salida, guía de herramientas y límites. [Anthropic engineering](https://www.anthropic.com/engineering/multi-agent-research-system)

**0x06.9 :: EJECUCIÓN SIN SUPERVISIÓN**

```
El éxito se ve así: <qué debe ser verdad>.
Al terminar, <escribe los resultados en ... / publica ...>. No puedes hacerme preguntas.
```
Las ejecuciones sin supervisión o programadas no pueden hacer preguntas aclaratorias, así que indica qué es el éxito y qué hacer con los resultados. [common-workflows](https://code.claude.com/docs/en/common-workflows)

**0x06.10 :: ABRE CON EL RESULTADO**

```
Al terminar, abre con el resultado: tu primera frase debe responder
"qué pasó" o "qué encontraste", con el detalle de apoyo después.
```
Ejemplo oficial de Opus 5. [Opus 5 guide](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)

### Cuando te atascas

Después de dos correcciones fallidas sobre el mismo problema, ejecuta `/clear` y escribe un solo prompt nuevo que incorpore lo que aprendiste, en lugar de una tercera corrección. La documentación dice que esto funciona mejor casi siempre; una tercera corrección casi solo se suma a una conversación que ya contiene dos intentos fallidos que el agente sigue releyendo. [best-practices](https://code.claude.com/docs/en/best-practices)


---

## 0x07 :: AJUSTES: Protecciones que configuras una sola vez

Verificado contra la documentación de Anthropic, 2026-11-14. Se indican los requisitos de versión; los nombres y los valores por defecto pueden cambiar.

### Ventana de autocompactación

- Se configura por modelo con `/autocompact` (p. ej. `/autocompact 500k`, que se guarda en `modelSettings`; `/autocompact auto` restaura el valor por defecto optimizado; guardar por modelo requiere v2.1.288+).
- Para todos los modelos, usa el ajuste `autoCompactWindow` (p. ej. `200000` en `~/.claude/settings.json`), `--autocompact` para una sola ejecución o la variable de entorno `CLAUDE_CODE_AUTO_COMPACT_WINDOW`, que tiene prioridad a menos que Claude Code ignore el valor.
- El comando y la opción aceptan de 100K a 1M tokens, y la ventana tiene como tope la ventana de contexto del modelo.
- Precaución: un valor sin sufijo en la variable de entorno es un conteo bruto de tokens (`200` significa 200 tokens), mientras que `/autocompact 200` significa 200,000. Los valores de entorno fuera de rango generan una advertencia y se ajustan al límite del rango; un sufijo k/M en la variable de entorno requiere v2.1.304+.

Fuente: [model-config](https://code.claude.com/docs/en/model-config.md)

En los modelos con una ventana de contexto nativa de 1M (modelos Fable, Sonnet 5 y posteriores, Haiku 5.5, Opus 4.7 y posteriores), la autocompactación ocurre por defecto en torno a 967K tokens. [model-config](https://code.claude.com/docs/en/model-config.md) Consejo: como cada solicitud lleva el contexto, una ventana más pequeña reduce el tamaño de cada solicitud. Ese es el razonamiento de esta guía, no una afirmación citada.

### TTL de la caché

- `promptCacheTtl` (o `CLAUDE_CODE_PROMPT_CACHE_TTL`) para la conversación principal y `subagentPromptCacheTtl` (o `CLAUDE_CODE_SUBAGENT_PROMPT_CACHE_TTL`) para todo lo demás, cada uno con `"5m"` o `"1h"` (v2.1.242+).
- Quienes usan clave de API o un proveedor en la nube pueden fijar `promptCacheTtl` en `"1h"` para una caché de una hora en la conversación principal.
- `FORCE_PROMPT_CACHING_5M=1` fuerza 5 minutos en ambos grupos y sirve para depurar o para anular los ajustes administrados.
- `ENABLE_PROMPT_CACHING_1H=1` pide 1 hora para ambos grupos.

Fuente: [prompt-caching](https://code.claude.com/docs/en/prompt-caching)

### Reduce el uso en reposo y en segundo plano

- `idleCompaction: false` deja de compactar una conversación que dejaste inactiva (v2.1.290+).
- `crossSessionInbound: "hold"` retiene los mensajes entrantes de otras sesiones en lugar de entregarlos.
- `CLAUDE_CODE_GOAL_CHECKIN_MINUTES=0` desactiva los chequeos de objetivo en inactividad.
- Las sugerencias de prompt se pueden desactivar.

Fuente: [costs](https://code.claude.com/docs/en/costs)

### Modelo del subagente

`CLAUDE_CODE_SUBAGENT_MODEL` define un modelo por defecto para los subagentes, pero ocupa el tercer lugar en precedencia: gana el parámetro `model` de cada invocación, luego el campo `model` de la definición del subagente, luego esta variable y luego el modelo de la conversación principal. Para aplicar un mismo modelo a todos los subagentes, teammates y agentes de workflow, defínela junto con `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1` (v2.1.257+); con FORCE, ya no se aplican los modelos del prompt de creación ni de la definición. Definir solo la variable no cambia los subagentes integrados Explore y Plan. En los teammates, un modelo indicado en el prompt de creación tiene prioridad sobre la variable, salvo que FORCE esté definido. [sub-agents](https://code.claude.com/docs/en/sub-agents), [agent-teams](https://code.claude.com/docs/en/agent-teams)

### Esfuerzo de razonamiento

Reduce el costo del razonamiento en tareas simples con `/effort` (o en `/model`), porque los tokens de razonamiento se facturan como tokens de salida. No puedes desactivar el razonamiento en Opus 5.5, Sonnet 5.5, Haiku 5.5 ni en los modelos Fable. Cambiar el esfuerzo a mitad de sesión conserva la caché en Fable 5.1 y posteriores, Opus 5.5, Sonnet 5.5 y Haiku 5.5 con clave de API o suscripción de Claude; en la mayoría de los demás modelos (y en Bedrock, Google Cloud's Agent Platform o un Claude apps gateway) la invalida. [costs](https://code.claude.com/docs/en/costs), [prompt-caching](https://code.claude.com/docs/en/prompt-caching)

### Inspeccionar

`/usage` y `/context`: ver 0x04. En `/usage`, presiona `d` o `w` para alternar entre las últimas 24 horas y los últimos 7 días. [costs](https://code.claude.com/docs/en/costs), [context-window](https://code.claude.com/docs/en/context-window.md)


---

## 0x08 :: NOTAS DE CAMPO: Una semana medida

> Esta sección es un caso de estudio: la semana de un desarrollador, medida a partir de los registros locales de sesión de Claude Code (`~/.claude/projects/*.jsonl`) y de `/usage`, y luego anonimizada. Las proporciones describen esa semana; las tuyas serán distintas. Léela junto a las secciones con fuentes de arriba.

### Qué pasó

Un límite semanal del plan llegó al 82% dos días después de reiniciarse. La elección de modelo y el esfuerzo de razonamiento casi no pesaron: los tokens de salida, que incluyen el razonamiento, fueron unos 16M frente a unos 3,700M de lecturas de caché. El tamaño del contexto fue lo que determinó el gasto:

- Una sesión estuvo abierta 9 días sin `/clear`.
- Su contexto promedió de 290K a 525K tokens por turno, con un pico de 911K. Cada turno, incluso un "ok, sigue", releía todo.
- Los agentes que lanzó (sobre todo integrantes de equipos) sumaron cerca del 64% del uso. Varios corrieron 400+ turnos, y uno corrió 1,209 turnos con el modelo más grande.
- Entre el reinicio y el día tres, la sesión líder inició ~670 turnos a partir de mensajes entrantes. Solo ~200 eran de la persona. 225 fueron notificaciones de inactividad de integrantes, 127 fueron mensajes de integrantes y 121 fueron notificaciones de tareas en segundo plano, cada una un turno con el contexto completo.
- `/usage` de la semana coincidía: el 89% del uso estuvo en sesiones activas durante 8+ horas distintas, el 75% cayó bajo su recomendación de "start fresh when you switch tasks", y un recordatorio programado costó 520K tokens en una sola ejecución porque se disparó dentro de una sesión enorme.

### Reglas que adoptamos (consejo)

- Haz un traspaso y usa `/clear` antes de que una sesión pase de ~300 a 500K tokens, o en cuanto cambie el tema.
- Un agente por entregable: "arregla los 13 hallazgos de la revisión" pasó a ser un agente para el bloqueante, uno para los mayores y los menores resueltos directamente.
- Con menos de ~10 pasos, no uses un agente: hazlo en la sesión principal.
- Dale a cada agente una línea de meta y un presupuesto de turnos (~100 turnos); después debe detenerse y resumir.
- Apaga los equipos de agentes a menos que los agentes necesiten hablar entre sí. Los subagentes devuelven un resultado y terminan.
- Programa los recordatorios desde una sesión nueva y chica.

Por qué ~300 a 500K: el costo por turno crece más o menos con el contexto. Si una sesión empieza cerca de 100K y crece de forma lineal hasta el punto de traspaso, el turno promedio queda más o menos a la mitad:

```
  traspaso en   contexto prom./turno   costo relativo
  300K          ~200K                  1.0x
  500K          ~300K                  1.5x
  sin límite    290-525K, 9 días       2-2.5x
```

### Prompt de traspaso (consejo)

```
Antes de limpiar esta sesión, escribe un traspaso en <HANDOFF.md> (máx. ~150 líneas).
Hazlo tú, sin agentes. Usa solo lo que ya sabes, más git para confirmar el estado.
1. Objetivo en 3 líneas.
2. Tabla de estado: ítem / rama / PR / tests.
3. Decisiones que no se reabren, una línea cada una con el porqué.
4. Próximos pasos en orden de prioridad, cada uno con su primera acción concreta.
5. Trampas conocidas. Marca como "sin verificar" lo que no puedas confirmar.
```

Luego `/clear` y: "Lee HANDOFF.md y sigamos con el punto #1."

### Prompt de presupuesto de agentes (consejo)

```
Para el resto de esta sesión:
- Lanza un agente solo si el trabajo corre de verdad en paralelo; si no, hazlo tú.
- Cada agente recibe un entregable, nunca "toda la especificación".
- Los agentes reportan en ~100 turnos; si no terminaron, que se detengan y resuman.
- Modelo de tamaño medio, salvo que yo pida expresamente el grande. Máximo 2 a la vez.
- Avísame cuando esta sesión pase de ~<400K> de contexto para hacer el traspaso.
```

### Prompt de diagnóstico primero (consejo)

```
Esto falla con: <pega el error exacto>
Encuentra la causa antes de editar nada. Muéstrame la causa y la evidencia,
y luego espera. No toques el código hasta que yo confirme.
```

### Pedir una decisión (consejo)

```
Máximo 3 opciones, una línea cada una con su contrapartida. Recomienda una.
Hazme como máximo una pregunta. Si es de rutina, decide y avísame en una línea.
```

### Trampa de ajustes que nos tocó

`autoCompactWindow` estaba definido de forma global, pero las sesiones igual se compactaban a los 800K. Las entradas por modelo bajo `modelSettings` tenían su propio `autoCompactWindow`, y la descripción del esquema de esa configuración dice que un valor por modelo reemplaza al de nivel superior para ese modelo. `/autocompact` escribe entradas por modelo, así que ejecutarlo puede volver a crear la anulación sin avisar. Revisa `modelSettings` si el valor global parece ignorarse.

---

```
-[ EOF ]-------------------------------------------------------------
  saludos a quien alguna vez se quedó sin contexto a las 3 a. m.
  no hay cuchara. solo hay contexto.
---------------------------------------------------------------------
  prompt-playbook :: v0x01 :: datos revisados el 2026-11-14
```
