#!/usr/bin/env bash
# Termina con 0 si .env tiene LLM_BASE_URL y LLM_API_KEY con valor (docker-compose.yml las exige).
[ -f .env ] || exit 1
grep -qE '^LLM_BASE_URL=[^[:space:]]+' .env && grep -qE '^LLM_API_KEY=[^[:space:]]+' .env
