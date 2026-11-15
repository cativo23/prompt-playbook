# Implementation Plan: Versión en español del Prompt Playbook

**Branch**: `feature/001-spanish-version` | **Date**: 2026-11-15 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/001-spanish-version/spec.md`

## Summary

Se publica la guía en español latinoamericano en `/es/`, como una copia traducida de `index.html`, y se agrega un toggle `EN | ES` a las dos páginas. El toggle es un link real que, si hay JS, lleva a la misma sección del otro idioma. La traducción sale primero a `content/final.es.md` con un glosario fijo, pasa la revisión anti-AI y después se porta al HTML. La página en inglés solo recibe el toggle y las etiquetas `hreflang`/`og:locale`.

## Technical Context

**Language/Version**: HTML5, CSS y JavaScript vanilla, todo inline (sin build)

**Primary Dependencies**: ninguna, salvo Google Fonts (como hoy)

**Storage**: N/A (sitio estático)

**Testing**: chequeos con shell (`grep`/`diff`) más verificación manual en el navegador (ver [quickstart.md](quickstart.md))

**Target Platform**: navegadores modernos, de celular y de escritorio, servidos por nginx:alpine detrás de Traefik en polaris2

**Project Type**: sitio estático de una página por idioma

**Performance Goals**: la página ES pesa lo mismo que la EN (~71 KB), y el toggle no agrega peticiones

**Constraints**: sin build, sin dependencias nuevas; el toggle funciona sin JS; no cambia el contenido visible en inglés

**Scale/Scope**: 1 página nueva (~310 líneas de fuente para traducir, 87 enlaces de fuente), un toggle en 2 páginas y una línea en el deploy

## Constitution Check

`.specify/memory/constitution.md` todavía es la plantilla vacía. Como gates se usan las reglas del README del proyecto:

| Gate (README) | Cumple | Cómo |
|---|---|---|
| Ninguna afirmación sin enlace de fuente | ✅ | Mismos enlaces; chequeo #1 del quickstart |
| Lo que no tiene fuente va como "Advice" | ✅ | Rótulo fijo "Consejo"; chequeo #6 |
| Solo ejemplos genéricos | ✅ | Los ejemplos se traducen sin agregar contenido de trabajo |
| Editar primero el fuente y después el HTML | ✅ | `final.es.md` → `es/index.html` (R6) |
| Pasada anti-AI a la prosa nueva | ✅ | R5; chequeo #7 |

**Re-check después del diseño**: sin violaciones.

## Project Structure

### Documentation (this feature)

```text
specs/001-spanish-version/
├── spec.md
├── plan.md              # este archivo
├── research.md          # decisiones R1–R7
├── data-model.md        # páginas, secciones, glosario
├── quickstart.md        # verificación
├── contracts/
│   └── language-toggle.md
├── checklists/
│   └── requirements.md
└── tasks.md             # lo genera /speckit-tasks
```

### Source Code (repository root)

```text
index.html               # MODIFICA: toggle + hreflang/og:locale (nada visible más)
es/
└── index.html           # NUEVO: copia traducida, rutas de assets absolutas
content/
├── final.md             # sin cambios
└── final.es.md          # NUEVO: fuente del texto en español
deploy/
└── deploy.sh            # MODIFICA: rsync incluye es/index.html
README.md                # MODIFICA: tabla de layout + regla "actualizar ES en el mismo cambio"
```

**Structure Decision**: se mantiene el patrón de un archivo por página sin build. La versión en español es un directorio `es/` con su propio `index.html`. CSS y JS quedan duplicados a propósito (R2).

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| CSS/JS duplicado en 2 archivos | No tocar la página EN más allá del toggle (FR-002) | Extraerlos a `assets/` es un refactor fuera del alcance pedido |
