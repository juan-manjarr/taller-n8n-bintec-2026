#!/usr/bin/env bash
# Espera a que el Docker interno del codespace (docker-in-docker) acepte comandos.
for _ in $(seq 1 60); do
  docker info >/dev/null 2>&1 && exit 0
  sleep 2
done
echo "Docker no arrancó dentro del codespace" >&2
exit 1
