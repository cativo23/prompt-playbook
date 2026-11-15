# Contract: toggle de idioma y URLs

## URLs públicas

| URL | Contenido | Estado esperado |
|---|---|---|
| `/` | Guía en inglés | 200, `lang="en"` |
| `/es/` | Guía en español | 200, `lang="es-419"` |
| `/es` | Redirige a `/es/` o la sirve | Nunca la página en inglés |
| `/es/#<id>` | Guía en español en la sección `<id>` | Mismo `id` que en inglés |
| `/assets/*` | Assets compartidos | 404 si falta el archivo (sin fallback) |

## Toggle (mismo markup en las dos páginas, cambia solo `aria-current`)

```html
<nav class="lang" aria-label="Language / Idioma">
  <a href="/"    lang="en" hreflang="en" [aria-current="true" en la página EN]>EN</a>
  <a href="/es/" lang="es" hreflang="es" [aria-current="true" en la página ES]>ES</a>
</nav>
```

**Comportamiento**
1. Sin JS: el link lleva al inicio de la otra versión.
2. Con JS: al hacer clic se le agrega `#<id>` de la `section.chapter` visible en ese momento. Si el lector está en el hero, no se agrega nada.
3. El enlace al idioma actual no navega ni recarga.
4. Visible al hacer scroll, a 375 px de ancho y en escritorio, y alcanzable con Tab.

## `<head>` de cada página

```html
<link rel="alternate" hreflang="en"        href="https://nospoon.cativo.dev/">
<link rel="alternate" hreflang="es"        href="https://nospoon.cativo.dev/es/">
<link rel="alternate" hreflang="x-default" href="https://nospoon.cativo.dev/">
```
En la página ES, además: `og:url` = `/es/`, `og:locale` = `es_LA`, `og:locale:alternate` = `en_US`, y título, descripción, `og:*` y `twitter:*` en español. La imagen es la misma.
