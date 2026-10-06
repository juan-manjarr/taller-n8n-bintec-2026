#!/usr/bin/env bash
# Se ejecuta cada vez que el codespace arranca o se reanuda: vuelve a levantar los contenedores
# (solo si .env ya tiene la URL y la llave; si no, docker compose fallaría).
set -euo pipefail
cd "$(dirname "$0")/.."

bash .devcontainer/env-listo.sh || exit 0
bash .devcontainer/wait-docker.sh
docker compose up -d
