# Research: Versión en español

Todas las decisiones se apoyan en el código actual (`index.html`, `deploy/`, `content/final.md`) revisado el 2026-11-15.

## R1. Dónde vive la página en español

- **Decision**: `es/index.html`, servida en `https://nospoon.cativo.dev/es/`.
- **Rationale**: Cumple FR-001 (dirección propia y compartible). Mantiene el patrón de un archivo por página sin build. nginx ya la sirve: `try_files $uri $uri/ /index.html` resuelve `/es/` a `es/index.html` sin tocar la config.
- **Alternatives considered**: (a) un solo HTML con las dos versiones y un botón JS. Se descartó porque duplica el peso de la página, Google indexa un solo idioma y el idioma no viaja en el link (decidido con Carlos el 2026-11-15). (b) `index.es.html` en la raíz: queda una URL fea y el contenido negociado no aporta nada en un sitio estático.

## R2. Cómo se arma `es/index.html`

- **Decision**: copiar `index.html` y traducir el texto en el lugar. El CSS y el JS quedan duplicados dentro de cada archivo.
- **Rationale**: FR-002 prohíbe tocar el contenido en inglés y Carlos pidió "nada más que eso". Extraer el CSS y el JS a archivos compartidos sería un refactor de la página en inglés.
- **Alternatives considered**: un `assets/site.css` y un `assets/site.js` compartidos. Es mejor a largo plazo, pero queda fuera de alcance. Se anota como deuda: un cambio de diseño ahora toca dos archivos.
- **Consecuencia**: en `es/index.html` las rutas relativas (`assets/icon.png`) se rompen. Pasan a ser absolutas (`/assets/icon.png`). La imagen para redes (`og:image`) ya es absoluta.

## R3. Toggle: misma sección sin depender de JS

- **Decision**: el toggle es un `<a>` real (`/` ↔ `/es/`), así que funciona sin JS (FR-010). Un script chico intercepta el clic, busca la sección `section.chapter[id]` visible en ese momento y le agrega `#id` al destino (FR-009). Sin JS, el link lleva al inicio de la otra versión.
- **Rationale**: la página no tiene scroll-spy, así que el hash de la URL solo existe si el lector usó el índice. Por eso hay que calcular la sección en el momento del clic.
- **Requisito derivado**: las dos páginas comparten los mismos `id` de sección (`why`, `formula`, `examples`, `agents`, `context`, `output`, `pocket`, `settings`, `field`). Esos ids no se traducen.
- **Ubicación**: fijo en la esquina superior derecha, en las dos páginas, para que se pueda alcanzar desde cualquier sección. Con estética de terminal: `[ EN | ES ]`, el idioma actual resaltado y marcado con `aria-current="true"`, y cada opción con `lang` y `hreflang`.

## R4. Idioma declarado y SEO

- **Decision**: `<html lang="es-419">` en la página en español. En las dos páginas, `<link rel="alternate" hreflang="en" href="https://nospoon.cativo.dev/">`, `hreflang="es"` → `/es/` y `hreflang="x-default"` → `/`. Para redes: `og:locale` `es_LA` en la española y `en_US` en la inglesa, cada una con `og:locale:alternate` apuntando a la otra.
- **Rationale**: `es-419` (español de Latinoamérica) es una etiqueta BCP 47 válida para `lang`. En `hreflang` se usa `es` a secas para no depender de que el buscador acepte el código de región 419 (sin verificar), y como es la única versión en español, cubre a todos los hispanohablantes.
- **Nota**: lo único que se agrega a la página en inglés son las etiquetas `hreflang` y `og:locale`, y no cambian nada visible.

## R5. Revisión anti-AI en español

- **Decision**: usar la skill `avoid-ai-writing` en modo `edit` con `--context docs` sobre `content/final.es.md`. La skill tiene sus listas de patrones en inglés, así que se aplican sus clases de patrón con los equivalentes en español: muletillas ("es importante destacar", "cabe mencionar", "en el panorama actual", "sin lugar a dudas"), adjetivos inflados ("crucial", "fundamental", "clave", "robusto"), "no solo… sino también", tríadas por reflejo, guiones largos usados como muletilla, cierres que resumen lo ya dicho y frases citables sin contenido.
- **Rationale**: FR-007 pide "la misma revisión". La skill no trae una lista en español, y traducir sus categorías es la forma de aplicar el mismo criterio.
- **Vigilar también los calcos del inglés**: voz pasiva con "ser" ("es leído por"), "en orden de", "aplicar" por "postularse", "eventualmente" por "al final", y gerundios encadenados.

## R6. Traducción: flujo y consistencia

- **Decision**: (1) se escribe `content/final.es.md` traduciendo `content/final.md` sección por sección con el glosario de `data-model.md`. (2) Se le hace la pasada anti-AI. (3) Se porta al HTML. El fuente manda, igual que hoy (FR-013).
- **Rationale**: el glosario fijo evita que el mismo término salga traducido de tres formas distintas si se reparte el trabajo por secciones.
- **Ejemplos (0x02, 0x06)**: los prompts de ejemplo se traducen a español natural, como los escribiría alguien en la región. Rutas, nombres de archivos y comandos quedan igual. El ejemplo literal de la documentación (`cat error.log | claude -p "what's going on here"`) se deja tal cual porque es una cita con fuente.
- **Matrix**: "follow the white rabbit" → "sigue al conejo blanco", "there is no spoon" → "no hay cuchara". Son las frases como se conocen en Latinoamérica.

## R7. Despliegue

- **Decision**: agregar `--include 'es/' --include 'es/index.html'` a la lista de rsync de `deploy/deploy.sh`.
- **Rationale**: hoy solo se suben `index.html` y `assets/` (lista de inclusión explícita). Sin este cambio, `/es/` cae en el fallback de nginx y devuelve la página en inglés con un 200, que es justo el problema que oculta los 404 (ver reference_deploy_nginx_rsync).
- **Desplegar a producción es un paso hacia afuera**: se confirma con Carlos antes de hacerlo.
