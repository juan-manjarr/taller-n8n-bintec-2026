#!/usr/bin/env bash
# Se ejecuta una vez, al crear el codespace: prepara .env, descarga las imágenes y, si .env ya
# tiene la URL y la llave, levanta n8n + servicios mock.
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f .env ] || cp .env.example .env

bash .devcontainer/wait-docker.sh
# docker-compose.yml exige LLM_BASE_URL y LLM_API_KEY hasta para descargar imágenes:
# aquí se pasan valores provisionales solo para el pull (no se guardan en .env).
LLM_BASE_URL=pendiente LLM_API_KEY=pendiente docker compose pull --quiet

if bash .devcontainer/env-listo.sh; then
  docker compose up -d
  bash .devcontainer/wait-n8n.sh
  cat <<'EOF'

==================================================================
 Entorno del taller listo (n8n + Risk/Fraud/CRM API).
 Abre n8n: pestaña PORTS -> fila "n8n (5678)" -> ícono del globo.
 Usuario admin@bintec.local / contraseña Bintec2026!
==================================================================
EOF
else
  cat <<'EOF'

==================================================================
 Imágenes descargadas. Falta un paso:
 1. Abre el archivo .env y completa LLM_BASE_URL y LLM_API_KEY
    (las del correo del taller o tu API key de Gemini).
 2. En esta terminal ejecuta:   docker compose up -d
 3. Abre n8n: pestaña PORTS -> fila "n8n (5678)" -> ícono del globo.
    Usuario admin@bintec.local / contraseña Bintec2026!
==================================================================
EOF
fi
