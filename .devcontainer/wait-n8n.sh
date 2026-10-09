#!/usr/bin/env bash
# Espera a que n8n responda en el puerto 5678 (el primer arranque migra la base de datos).
for _ in $(seq 1 90); do
  curl -sf http://localhost:5678/healthz >/dev/null && exit 0
  sleep 2
done
echo "n8n no respondió en http://localhost:5678; revisa: docker compose logs n8n" >&2
exit 1
