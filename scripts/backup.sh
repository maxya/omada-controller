#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
HOST_COMPOSE="${ROOT_DIR}/compose/docker-compose.host.yml"
BACKUP_COMPOSE="${ROOT_DIR}/compose/profiles/backup.yml"
RETENTION="${BACKUP_RETENTION_COUNT:-7}"

[[ -f "${ENV_FILE}" ]] || {
  echo "ERROR: missing .env" >&2
  exit 1
}

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

RETENTION="${BACKUP_RETENTION_COUNT:-7}"

mkdir -p "${ROOT_DIR}/backups/mongodb"

restart_controller=false
controller_id="$(docker compose --env-file "${ENV_FILE}" -f "${HOST_COMPOSE}" ps -q omada-controller 2>/dev/null || true)"
if [[ -n "${controller_id}" ]]; then
  restart_controller=true
fi

docker compose --env-file "${ENV_FILE}" -f "${HOST_COMPOSE}" stop omada-controller
docker compose --env-file "${ENV_FILE}" -f "${HOST_COMPOSE}" -f "${BACKUP_COMPOSE}" --profile backup run --rm mongodb-backup

if [[ "${restart_controller}" == "true" ]]; then
  docker compose --env-file "${ENV_FILE}" -f "${HOST_COMPOSE}" up -d omada-controller
fi

mapfile -t backups < <(find "${ROOT_DIR}/backups/mongodb" -mindepth 1 -maxdepth 1 -type d | sort)
if (( ${#backups[@]} > RETENTION )); then
  remove_count=$(( ${#backups[@]} - RETENTION ))
  for (( i = 0; i < remove_count; i++ )); do
    rm -rf "${backups[$i]}"
  done
fi

echo "OK: backup complete"
