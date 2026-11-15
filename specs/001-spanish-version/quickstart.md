# Quickstart: verificar la versión en español

## Local

```bash
cd ~/projects/personal/prompt-playbook
python3 -m http.server 8077   # abrir http://127.0.0.1:8077/ y http://127.0.0.1:8077/es/
```

## Chequeos automáticos (cada uno debe salir limpio)

| # | Qué prueba | Cómo | Esperado |
|---|---|---|---|
| 1 | Mismos enlaces de fuente (SC-002) | `diff <(grep -o 'class="src" href="[^"]*"' index.html \| sort) <(grep -o 'class="src" href="[^"]*"' es/index.html \| sort)` | sin diferencias |
| 2 | Mismos ids de sección (SC-003) | `diff <(grep -o 'section class="chapter" id="[^"]*"' index.html) <(grep -o '...' es/index.html)` | sin diferencias |
| 3 | Cifras de 0x08 iguales (SC-004) | extraer los números de la sección `id="field"` de cada página y compararlos | idénticas, en el mismo orden |
| 4 | Sin formas peninsulares ni voseo (SC-006) | `grep -inwE 'vosotros\|vuestr[oa]s?\|ordenador\|móvil\|fichero\|tenés\|podés\|querés\|hacé\|mirá\|sabés' es/index.html content/final.es.md` | sin resultados |
| 5 | Sin inglés suelto (SC-001) | `grep -nwE 'the\|and\|with\|your\|you' es/index.html` fuera de `<code>`, `href` y citas | solo términos permitidos (FR-006) |
| 6 | Rótulo de consejo uniforme (FR-008) | `grep -c 'Advice' es/index.html` = 0 y la cantidad de `Consejo` = la de `Advice` en inglés | coincide |
| 7 | Anti-AI (SC-005) | `avoid-ai-writing --mode detect` sobre `content/final.es.md` | sin hallazgos |
| 8 | Assets cargan desde `/es/` | `curl -sI 127.0.0.1:8077/assets/icon.png` y revisar en DevTools que no haya 404 | 200 |

## Chequeos manuales

- Toggle EN→ES y ES→EN desde 0x00, 0x04 y 0x08: llega a la misma sección (SC-003).
- Toggle con JS desactivado: cambia de idioma (SC-007).
- Celular (375 px) y escritorio: el toggle se ve y se puede tocar (SC-007).
- Tab hasta el toggle: el lector de pantalla anuncia los idiomas y cuál es el actual.
- Titular animado en español, botón "copiar" → "copiado", lluvia de Matrix funcionando (FR-014).
- Vista previa para redes de `/es/` con título y descripción en español (SC-008), por ejemplo con un validador de Open Graph.

## Producción (solo con OK de Carlos)

```bash
./deploy/deploy.sh
curl -s -o /dev/null -w '%{http_code}\n' https://nospoon.cativo.dev/es/   # 200
curl -s https://nospoon.cativo.dev/es/ | grep -o '<html lang="[^"]*"'      # es-419
```
