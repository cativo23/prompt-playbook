#!/usr/bin/env bash
# Verifies that es/index.html stays in sync with index.html.
# Run it after any change to either page. Exit code != 0 means something drifted.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

EN=index.html
ES=es/index.html
fail=0
ok()  { printf '  ok    %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=1; }

if [[ ! -f $ES ]]; then echo "  FAIL  $ES does not exist"; exit 1; fi

# 1. Same source links, same destinations
if diff <(grep -o 'class="src" href="[^"]*"' "$EN" | sort) <(grep -o 'class="src" href="[^"]*"' "$ES" | sort) >/dev/null; then
  ok "source links match ($(grep -o 'class="src" href=' "$EN" | wc -l))"
else bad "source links differ"; fi

# 2. Same section ids, same order
if diff <(grep -o 'section class="chapter" id="[^"]*"' "$EN") <(grep -o 'section class="chapter" id="[^"]*"' "$ES") >/dev/null; then
  ok "section ids match"
else bad "section ids differ"; fi

# 3. Same figures in 0x08 (field notes)
nums() { sed -n '/id="field"/,/<\/section>/p' "$1" | sed 's/<[^>]*>//g' | grep -oE '[0-9][0-9.,%$]*' ; }
if diff <(nums "$EN") <(nums "$ES") >/dev/null; then
  ok "0x08 figures match ($(nums "$EN" | wc -l))"
else bad "0x08 figures differ: diff <(nums $EN) <(nums $ES)"; fi

# 4. Latin American Spanish: no vosotros, no voseo, no Spain-only words
# Only the stressed voseo forms count: 'usa', 'mira', 'hace' are valid tú/él forms.
hits=$(sed 's/<[^>]*>/ /g' "$ES" content/final.es.md 2>/dev/null | grep -inwoE 'vosotr[oa]s|vuestr[oa]s?|ordenador(es)?|móvil(es)?|ficheros?|tenés|podés|querés|hacé|mirá|sabés|usá|poné|fijate|dale que' || true)
if [[ -z $hits ]]; then ok "no voseo / Spain-only forms"; else bad "found: $(echo "$hits" | tr '\n' ' ')"; fi

# 5. Advice label translated consistently
en_adv=$(grep -o 'Advice' "$EN" | wc -l)
es_adv=$(grep -o 'Advice' "$ES" | wc -l)
es_con=$(grep -o 'class="adv">Consejo' "$ES" | wc -l)
en_cls=$(grep -o 'class="adv">Advice' "$EN" | wc -l)
if [[ $es_adv -eq 0 && $es_con -eq $en_cls ]]; then ok "Advice -> Consejo ($es_con labels)"
else bad "Advice label: EN=$en_adv (labels $en_cls), ES Advice=$es_adv, ES Consejo labels=$es_con"; fi

# 6. Declared language
if grep -q '<html lang="es-419">' "$ES"; then ok "lang=es-419"; else bad "missing <html lang=\"es-419\">"; fi

# 7. Language toggle + hreflang on both pages
for f in "$EN" "$ES"; do
  if grep -q '<nav class="lang"' "$f" && grep -q 'href="/es/"' "$f" \
     && grep -q 'hreflang="en"' "$f" && grep -q 'hreflang="es"' "$f" && grep -q 'hreflang="x-default"' "$f"; then
    ok "toggle + hreflang in $f"
  else bad "toggle or hreflang missing in $f"; fi
done

exit $fail
