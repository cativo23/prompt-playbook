#!/usr/bin/env bash
# Deploys the Prompt Playbook to nospoon.cativo.dev on polaris2.
# Same pattern as paldea-guide: nginx:alpine on a read-only volume, Traefik routes by label.
# Only index.html is published; styles/, content/ and backups stay local.
set -euo pipefail

HOST="polaris2"
REMOTE="/home/cativo23/deploy/prompt-playbook"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ssh "$HOST" "mkdir -p '$REMOTE/html'"
rsync -az --delete --include 'index.html' --include 'es/' --include 'es/index.html' --include 'assets/' --include 'assets/og.png' --include 'assets/icon.png' --exclude '*' "$SRC/" "$HOST:$REMOTE/html/"
scp -q "$SRC/deploy/compose.prod.yml" "$HOST:$REMOTE/compose.prod.yml"
scp -q "$SRC/deploy/nginx.conf" "$HOST:$REMOTE/nginx.conf"
ssh "$HOST" "cd '$REMOTE' && docker compose -f compose.prod.yml up -d"
ssh "$HOST" "docker exec prompt-playbook-app-1 nginx -t && docker exec prompt-playbook-app-1 nginx -s reload" >/dev/null 2>&1 \
  && echo "==> nginx reloaded"
ssh "$HOST" "ls -A '$REMOTE/html'; docker ps --filter name=prompt-playbook --format '  {{.Names}}  {{.Status}}'"
echo "==> https://nospoon.cativo.dev"
