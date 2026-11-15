# Feature Specification: Versión en español del Prompt Playbook

**Feature Branch**: `feature/001-spanish-version`

**Created**: 2026-11-15

**Status**: Draft

**Input**: User description: "Hacer una versión en español del playbook. Es el mismo texto, traducido, sin cambiar el significado; los ejemplos pueden ser otros. Pasarle la revisión anti-AI igual que a la versión actual. Español latinoamericano. Tiene que haber un toggle de idioma. No hacer nada más que eso."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Leer la guía completa en español (Priority: P1)

Una persona hispanohablante de Latinoamérica abre la versión en español y lee la guía completa (intro, índice, secciones 0x00 a 0x08 y pie) en un español natural de la región, con el mismo contenido, las mismas fuentes y la misma estética que la versión en inglés.

**Why this priority**: Es la feature en sí. Sin esto, el toggle no tiene a dónde llevar.

**Independent Test**: Abrir la versión en español directamente por su dirección y leerla de punta a punta sin pasar por la versión en inglés. Ningún texto visible queda en inglés, salvo los términos técnicos que se mantienen a propósito (ver FR-006).

**Acceptance Scenarios**:

1. **Given** la versión en español publicada, **When** alguien la abre, **Then** ve las mismas 9 secciones, en el mismo orden y con los mismos números hexadecimales que la versión en inglés.
2. **Given** cualquier afirmación con fuente en la versión en inglés, **When** se busca su equivalente en español, **Then** existe, dice lo mismo y enlaza a la misma fuente.
3. **Given** una línea marcada como consejo ("Advice") en inglés, **When** se lee en español, **Then** sigue marcada como consejo y no se presenta como un hecho.
4. **Given** la sección 0x08 (notas de campo), **When** se lee en español, **Then** conserva todas las cifras sin cambios y sigue rotulada como caso de estudio, no como documentación.

---

### User Story 2 - Cambiar de idioma con el toggle (Priority: P2)

Quien está leyendo en un idioma ve un control visible "EN · ES" que marca el idioma actual y lo lleva a la misma guía en el otro idioma. Si estaba en una sección concreta (por ejemplo, 0x04), llega a esa misma sección del otro idioma.

**Why this priority**: Es la forma en que la gente descubre y alterna las dos versiones. Depende de que la P1 exista.

**Independent Test**: Desde la versión en inglés, ir a la sección 0x04, usar el toggle y comprobar que se abre la sección 0x04 en español. Repetir en sentido contrario.

**Acceptance Scenarios**:

1. **Given** la versión en inglés, **When** se usa el toggle, **Then** se abre la versión en español y el toggle marca "ES" como actual.
2. **Given** un lector posicionado en una sección, **When** cambia de idioma, **Then** llega a la misma sección en el otro idioma.
3. **Given** un enlace compartido a la versión en español (con o sin sección), **When** otra persona lo abre, **Then** ve la guía en español, sin pasos extra.
4. **Given** un navegador con JavaScript desactivado, **When** se usa el toggle, **Then** cambia de idioma igual.
5. **Given** un lector de pantalla o navegación por teclado, **When** llega al toggle, **Then** se anuncia el idioma de cada opción y cuál es el actual.

---

### Edge Cases

- Un enlace a una sección que no existe en el otro idioma: no puede pasar, porque las dos versiones comparten los mismos identificadores de sección.
- Ejemplos de prompts (los "PATCH" de 0x02 y los "pocket prompts" de 0x06): se traducen o se reemplazan por equivalentes en español que demuestren lo mismo. Comandos, rutas, nombres de archivos, claves de configuración y fragmentos de código no se traducen.
- Citas o frases tomadas literalmente de la documentación (por ejemplo, el ejemplo `cat error.log | claude -p "..."`): el comando queda igual. Si se traduce la frase de ejemplo, se aclara que el original está en inglés cuando eso cambie el sentido.
- Referencias culturales de Matrix ("follow the white rabbit", "there is no spoon"): se usan las frases con las que se conocen en el doblaje latinoamericano, no traducciones literales.
- El banner ASCII "PROMPT PLAYBOOK" y el nombre del sitio quedan igual: son marca, no texto.
- Si alguien comparte la versión en español en redes, la vista previa muestra título y descripción en español.
- Cuando cambie la versión en inglés, la española queda desactualizada hasta que se actualice (ver Assumptions).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: El sitio MUST ofrecer una versión completa en español con su propia dirección estable, separada de la versión en inglés, para que pueda enlazarse y compartirse directamente.
- **FR-002**: La versión en inglés MUST seguir en su dirección actual, sin cambios de contenido; solo se le agrega el toggle.
- **FR-003**: La versión en español MUST cubrir todo el texto visible: intro, índice, notas iniciales, las 9 secciones, etiquetas de diagramas y tablas, textos de botones y pie de página.
- **FR-004**: Cada afirmación MUST conservar su significado y su enlace de fuente. La versión en español MUST tener la misma cantidad de enlaces de fuente que la de inglés.
- **FR-005**: El texto MUST estar en español latinoamericano neutro: tuteo ("tú"), sin "vosotros" ni voseo, y vocabulario de la región ("computadora", "archivo", "celular").
- **FR-006**: Los términos técnicos que la gente usa tal cual en español MUST quedar sin traducir: comandos (`/clear`, `/compact`), nombres de herramientas y productos, claves de configuración, rutas, código, y palabras como "prompt", "token" y "subagente". La primera aparición de un término no obvio puede llevar una aclaración breve.
- **FR-007**: El texto traducido MUST pasar la misma revisión anti-AI que pasó la versión en inglés, y no puede quedar ninguna muletilla de texto generado por IA que la revisión marque.
- **FR-008**: El rótulo de consejo ("Advice") MUST tener un equivalente fijo en español, usado igual en toda la página.
- **FR-009**: Las dos versiones MUST tener un toggle de idioma visible en la misma posición que muestre ambos idiomas, marque el actual y lleve a la misma sección del otro idioma.
- **FR-010**: El toggle MUST funcionar sin JavaScript y ser accesible con teclado y lector de pantalla.
- **FR-011**: Cada versión MUST declarar su idioma y anunciar la existencia de la otra a los buscadores, para que ambas se indexen como versiones de la misma página.
- **FR-012**: La versión en español MUST tener título, descripción y textos de vista previa para redes en español.
- **FR-013**: El texto en español MUST tener su propio archivo fuente junto al fuente en inglés, que manda sobre el HTML igual que hoy (primero se edita el fuente y después la página).
- **FR-014**: La versión en español MUST verse y comportarse igual que la de inglés: mismo diseño, animaciones, lluvia de Matrix y efecto de escritura en el titular (con la palabra en español).

### Key Entities

- **Texto fuente en inglés**: el contenido actual de la guía. Es la referencia para el significado.
- **Texto fuente en español**: la traducción, con la misma estructura de secciones e identificadores que el inglés.
- **Sección**: unidad de contenido con número hexadecimal (0x00 a 0x08) e identificador compartido entre idiomas.
- **Enlace de fuente**: referencia a la documentación oficial que respalda una afirmación. Es igual en ambos idiomas.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: El 100% del texto visible de la versión en español está en español, salvo los términos de FR-006. Se verifica recorriendo la página completa.
- **SC-002**: Las dos versiones tienen exactamente la misma cantidad de enlaces de fuente y el mismo conjunto de destinos.
- **SC-003**: Las 9 secciones tienen el mismo identificador en ambos idiomas, y el cambio de idioma lleva a la misma sección en las 9.
- **SC-004**: Las cifras de la sección 0x08 coinciden al 100% con las de la versión en inglés.
- **SC-005**: La revisión anti-AI sobre el texto en español termina sin hallazgos pendientes.
- **SC-006**: Una lectura completa no encuentra formas peninsulares ("vosotros", "ordenador", "móvil") ni voseo.
- **SC-007**: El toggle funciona en celular y en escritorio, con y sin JavaScript, y cambia de idioma con un solo clic o toque.
- **SC-008**: Al compartir la versión en español, la vista previa muestra el título y la descripción en español.

## Assumptions

- **Alcance cerrado**: traducir, revisar anti-AI, publicar la versión en español y agregar el toggle. No se cambia el contenido en inglés, el diseño ni las fuentes, no se agregan otros idiomas y no hay detección del idioma del navegador ni redirecciones: el cambio de idioma es solo con el toggle.
- **Enlaces de fuente**: se mantienen los mismos enlaces (a la documentación en inglés) que se verificaron el 2026-11-14. Cambiarlos por versiones traducidas de la documentación obligaría a verificar de nuevo cada fuente, así que queda fuera de alcance. Una nota al inicio avisa que las fuentes están en inglés.
- **Imagen para redes**: la versión en español reutiliza la imagen de vista previa actual. Una imagen con texto en español queda fuera de alcance.
- **Mantenimiento**: cuando cambie el texto en inglés, el español se actualiza en el mismo cambio. Esta regla se agrega a las reglas de edición del README.
- **Fecha de verificación**: la versión en español muestra la misma fecha de verificación de datos que la de inglés (2026-11-14), porque los hechos son los mismos.
- **Publicación**: el proceso de despliegue actual se amplía para incluir la página en español. No cambia el servidor ni el dominio.
