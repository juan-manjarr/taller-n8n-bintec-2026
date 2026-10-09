#!/bin/sh
# Envía las solicitudes de ejemplo al webhook del flujo.
# Uso: ./scripts/test-flow.sh [archivo.json ...]
#   WEBHOOK_PATH=webhook-test  -> URL de prueba (flujo en "Listen for test event")
#   WEBHOOK_PATH=webhook       -> URL de producción (flujo publicado). Por defecto.
BASE_URL="${BASE_URL:-http://localhost:5678}"
WEBHOOK_PATH="${WEBHOOK_PATH:-webhook}"
cd "$(dirname "$0")/.." || exit 1

[ "$#" -eq 0 ] && set -- requests/*.json

for f in "$@"; do
  echo "=== $f"
  curl -sS -X POST "$BASE_URL/$WEBHOOK_PATH/solicitud-bancaria" \
    -H "Content-Type: application/json" \
    --data-binary "@$f"
  echo; echo
done
