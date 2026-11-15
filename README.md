# Prompt Playbook

A field guide to prompting coding agents, live at **https://nospoon.cativo.dev**.

Ask for work the agent can finish, keep the context small, and know what each turn costs. Sections 0x00 to 0x07 are built from official documentation, and every factual line links to its source. Lines marked "Advice" are rules of thumb. Section 0x08 holds field notes from one measured week of real usage, labeled as a case study.

## Layout

| Path | What it is |
|---|---|
| `index.html` | The whole site: one file, no build, no dependencies besides Google Fonts |
| `es/index.html` | Spanish (Latin American) version at `/es/`. Same markup, section ids and source links as `index.html` |
| `content/final.md` | Source of truth for the text. Edit here first, then the HTML |
| `content/final.es.md` | Source of truth for the Spanish text |
| `content/draft.md` | Pre-edit draft, kept for the diff |
| `assets/` | Share card (`og.png`) and favicon (`icon.png`) |
| `tools/check-es.sh` | Checks that `es/index.html` matches `index.html`: source links, section ids, 0x08 figures, language toggle |
| `tools/make-og.sh` | Renders `assets/` from `tools/og.html` and `tools/icon.html` with headless Chrome |
| `styles/` | The design explorations that led to the final look |
| `deploy/` | nginx + Traefik deploy to the host behind `nospoon.cativo.dev` |

## Rules for edits

- No factual claim without a source link. If it can't be sourced, label it as advice or drop it.
- Generic examples only.
- Docs and settings change fast: re-check version-gated facts before republishing.
- Every text change ships in both languages: update `content/final.md` and `content/final.es.md`, then both pages, then run `tools/check-es.sh`. Spanish is Latin American, with tú; the glossary is in `specs/001-spanish-version/data-model.md`.
