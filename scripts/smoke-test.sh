#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.host.yml"

[[ -f "${ENV_FILE}" ]] || {
  echo "ERROR: missing .env" >&2
  exit 1
}

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" ps
curl -fsS -k --max-time 10 -o /dev/null "https://127.0.0.1:${OMADA_MANAGE_HTTPS_PORT:-8043}/login"

echo "OK: Omada login endpoint responded"

