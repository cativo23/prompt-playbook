# Tasks: Versión en español del Prompt Playbook

**Input**: Design documents from `/specs/001-spanish-version/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/language-toggle.md, quickstart.md

**Tests**: no hay suite de tests. Por la regla TDD de Carlos, los chequeos automáticos del quickstart se escriben primero como script (`tools/check-es.sh`) y tienen que fallar antes de que exista la traducción.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: se puede hacer en paralelo (otro archivo, sin dependencias pendientes)
- **[Story]**: US1 = guía en español, US2 = toggle

## Path Conventions

Todo cuelga de la raíz del repo `~/projects/personal/prompt-playbook/`.

---

## Phase 1: Setup

**Purpose**: dejar la red de verificación lista antes de traducir.

- [x] T001 Crear `tools/check-es.sh` con los chequeos 1–6 del quickstart: enlaces de fuente iguales, ids de sección iguales, cifras de 0x08 iguales, sin voseo ni formas peninsulares, sin "Advice" en ES con la misma cantidad de "Consejo", y `lang="es-419"`. Sale con código ≠ 0 si alguno falla.
- [x] T002 Correr `tools/check-es.sh` y confirmar que falla porque `es/index.html` no existe (rojo).

---

## Phase 2: Foundational

**Purpose**: la base que necesitan las dos historias.

- [x] T003 Crear `es/index.html` como copia exacta de `index.html`.
- [x] T004 En `es/index.html`, cambiar las rutas relativas de assets a absolutas (`assets/icon.png` → `/assets/icon.png`, en `rel="icon"` y `rel="apple-touch-icon"`) (R2).
- [x] T005 Agregar `--include 'es/' --include 'es/index.html'` a la lista de rsync en `deploy/deploy.sh` (R7).

**Checkpoint**: `python3 -m http.server 8077` sirve `/es/` y carga el favicon sin 404.

---

## Phase 3: User Story 1 - Leer la guía completa en español (Priority: P1) 🎯 MVP

**Goal**: la guía completa en español latinoamericano en `/es/`, con el mismo significado, las mismas fuentes y las mismas cifras.

**Independent Test**: abrir `/es/` directamente, leerla completa y correr `tools/check-es.sh` → verde.

### Traducción del fuente (`content/final.es.md`), con el glosario de `data-model.md`

Las tareas de traducción se pueden repartir en paralelo porque cada una toca un bloque distinto del mismo archivo. Se escriben como fragmentos y se unen en T016.

- [x] T006 [P] [US1] Traducir intro, notas iniciales y 0x00 LA FÍSICA (líneas 1–49 de `content/final.md`) → `content/es-parts/00.md`
- [x] T007 [P] [US1] Traducir 0x01 LA FÓRMULA (líneas 50–72) → `content/es-parts/01.md`. "Advice" → "Consejo".
- [x] T008 [P] [US1] Traducir 0x02 ANTES / DESPUÉS (líneas 73–107) → `content/es-parts/02.md`. Los prompts de ejemplo pasan a español natural; rutas y archivos (`src/auth/`, `ExistingWidget.php`) y la cita `cat error.log | claude -p "what's going on here"` quedan igual.
- [x] T009 [P] [US1] Traducir 0x03 AGENTES (líneas 108–155) → `content/es-parts/03.md`
- [x] T010 [P] [US1] Traducir 0x04 HIGIENE DE CONTEXTO (líneas 156–191) → `content/es-parts/04.md`. `/clear` y `/compact` sin traducir.
- [x] T011 [P] [US1] Traducir 0x05 SALIDA (líneas 192–224) → `content/es-parts/05.md`
- [x] T012 [P] [US1] Traducir 0x06 PROMPTS DE BOLSILLO (líneas 225–319) → `content/es-parts/06.md`. Las plantillas copiables quedan en español y listas para usar.
- [x] T013 [P] [US1] Traducir 0x07 AJUSTES (líneas 320–367) → `content/es-parts/07.md`. Claves de configuración y valores sin traducir.
- [x] T014 [P] [US1] Traducir 0x08 NOTAS DE CAMPO (líneas 368–fin) → `content/es-parts/08.md`. Todas las cifras idénticas; sigue rotulada como caso de estudio.
- [x] T015 [US1] Revisar los 9 fragmentos contra el glosario: mismos términos en todas las secciones, tuteo, cero voseo y cero formas peninsulares.
- [x] T016 [US1] Unir los fragmentos en `content/final.es.md` y borrar `content/es-parts/`.
- [x] T017 [US1] Pasar `avoid-ai-writing` en modo `edit` con `--context docs` sobre `content/final.es.md`, con las clases de patrón adaptadas al español (R5), y repetir en modo `detect` hasta que no queden hallazgos (SC-005).
- [x] T018 [US1] Verificar que `content/final.es.md` tiene la misma cantidad de enlaces que `content/final.md` y los mismos destinos.

### Porte al HTML (`es/index.html`)

- [x] T019 [US1] `<head>` de `es/index.html`: `lang="es-419"`, `<title>`, `description`, `og:*` y `twitter:*` en español, `og:url` = `https://nospoon.cativo.dev/es/`, `og:locale` = `es_LA`, `og:locale:alternate` = `en_US` y el `alt` de la imagen en español (FR-012).
- [x] T020 [US1] Hero de `es/index.html`: zinehead, titular "Libera tu …" con el array del typewriter en español (`contexto.`, `límite semanal.`, `agentes.`, `contexto.`), párrafo principal y botones ("sigue al conejo blanco", …). El banner ASCII queda igual.
- [x] T021 [US1] Índice y notas iniciales de `es/index.html`, con los rótulos de `data-model.md`. Mantener el alineado con puntos del `<pre>` y agregar una nota de que las fuentes están en inglés.
- [x] T022 [US1] Portar 0x00–0x04 de `content/final.es.md` a `es/index.html`, sin tocar `id`, clases ni `href`.
- [x] T023 [US1] Portar 0x05–0x08 de `content/final.es.md` a `es/index.html`, sin tocar `id`, clases ni `href`.
- [x] T024 [US1] Textos de UI en el JS y en los atributos de `es/index.html`: botón `copy`/`copied` → `copiar`/`copiado`, `aria-label` del índice y de la navegación, y pie de página ("no hay cuchara…").
- [x] T025 [US1] Correr `tools/check-es.sh` → verde (los 6 chequeos).
- [x] T026 [US1] Chequeo 5 del quickstart (sin inglés suelto) y una lectura completa de `/es/` en el navegador.

**Checkpoint**: `/es/` es una guía completa en español y se puede publicar sola, aunque todavía no tenga toggle.

---

## Phase 4: User Story 2 - Cambiar de idioma con el toggle (Priority: P2)

**Goal**: un toggle `[ EN | ES ]` en las dos páginas que lleva a la misma sección del otro idioma (contrato en `contracts/language-toggle.md`).

**Independent Test**: desde 0x04 en inglés, usar el toggle → 0x04 en español, y al revés. Con JS desactivado, cambia de idioma igual.

- [x] T027 [US2] Agregar a `tools/check-es.sh` el chequeo de que las dos páginas tienen el `<nav class="lang">` con `/` y `/es/`, y los tres `hreflang` (`en`, `es`, `x-default`). Correr y confirmar que falla (rojo).
- [x] T028 [US2] Agregar a `index.html` el markup del toggle según el contrato (`aria-current="true"` en EN), más los `<link rel="alternate" hreflang>`, `og:locale` = `en_US` y `og:locale:alternate` = `es_LA`. Ningún otro cambio visible (FR-002).
- [x] T029 [P] [US2] Agregar a `es/index.html` el mismo markup (`aria-current="true"` en ES) y los `<link rel="alternate" hreflang>`.
- [x] T030 [US2] Agregar el CSS del toggle en los dos archivos (idéntico): fijo arriba a la derecha, estética de terminal, idioma actual resaltado, foco visible, área táctil cómoda a 375 px y sin tapar la barra de progreso ni el hero.
- [x] T031 [US2] Agregar el JS del toggle en los dos archivos (idéntico): al hacer clic, buscar la `section.chapter[id]` visible y agregarle `#id` al destino. En el hero no se agrega nada, y el idioma actual no navega.
- [x] T032 [US2] Correr `tools/check-es.sh` → verde.
- [x] T033 [US2] Chequeos manuales del quickstart para el toggle: EN↔ES desde 0x00, 0x04 y 0x08; con JS desactivado; a 375 px y en escritorio; teclado y lector de pantalla.

**Checkpoint**: las dos historias funcionan.

---

## Phase 5: Polish & Cross-Cutting

- [x] T034 [P] Actualizar `README.md`: tabla de layout (`es/index.html`, `content/final.es.md`, `tools/check-es.sh`) y una regla nueva: "Cuando cambie el texto en inglés, actualizar el español en el mismo cambio y correr `tools/check-es.sh`".
- [x] T035 Comparar `index.html` antes y después (`git diff main -- index.html`): solo cambiaron el toggle, `hreflang` y `og:locale`.
- [x] T036 Revisión final de FR-014 en `/es/`: lluvia de Matrix, typewriter, aparición al hacer scroll, barra de progreso y botones de copiar.
- [ ] T037 **Pedir OK a Carlos** antes de desplegar. Con el OK, correr `./deploy/deploy.sh` y los dos `curl` de la sección "Producción" del quickstart.

---

## Dependencies & Execution Order

### Phase Dependencies

- Setup (T001–T002) → Foundational (T003–T005) → US1 → US2 → Polish.
- T037 (deploy) va al final y necesita el OK explícito de Carlos.

### User Story Dependencies

- **US1** depende solo de Foundational. Es el MVP y se puede publicar sola.
- **US2** necesita que exista `es/index.html` (T003). Técnicamente puede empezar antes de terminar US1, pero T032 y T033 necesitan US1 completa para probar el salto entre secciones con contenido real.

### Within Each User Story

- US1: traducir (T006–T014) → revisar el glosario (T015) → unir (T016) → anti-AI (T017) → contar enlaces (T018) → portar al HTML (T019–T024) → verificar (T025–T026). El fuente siempre antes que el HTML.
- US2: chequeo en rojo (T027) → markup (T028–T029) → CSS (T030) → JS (T031) → verde (T032) → manual (T033).

### Parallel Opportunities

- T006–T014: las 9 secciones se traducen en paralelo, cada una en su fragmento.
- T028 y T029: archivos distintos.
- T034 en paralelo con T035 y T036.

## Parallel Example: User Story 1

```text
Lanzar juntas (cada una con el glosario de data-model.md y las reglas de FR-005/FR-006):
T006 intro+0x00 → content/es-parts/00.md
T007 0x01       → content/es-parts/01.md
T008 0x02       → content/es-parts/02.md
T009 0x03       → content/es-parts/03.md
T010 0x04       → content/es-parts/04.md
T011 0x05       → content/es-parts/05.md
T012 0x06       → content/es-parts/06.md
T013 0x07       → content/es-parts/07.md
T014 0x08       → content/es-parts/08.md
```

## Implementation Strategy

1. **MVP = US1**: Setup + Foundational + US1. `/es/` queda completa y verificada.
2. **Después US2**: el toggle en las dos páginas.
3. **Cierre**: README, diff de la página en inglés y revisión de animaciones.
4. **Deploy solo con OK de Carlos** (T037), así que todo lo anterior queda en la rama `feature/001-spanish-version` sin publicar.
