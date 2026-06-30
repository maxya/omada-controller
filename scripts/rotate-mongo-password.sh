#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.host.yml"
USER_TO_ROTATE="${ROTATE_USER:-omada}"
NEW_PASSWORD="${NEW_PASSWORD:-}"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ -f "${ENV_FILE}" ]] || die "missing .env"
[[ -n "${NEW_PASSWORD}" ]] || die "set NEW_PASSWORD to the replacement password"

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

case "${USER_TO_ROTATE}" in
  omada)
    auth_db="omada"
    env_key="OMADA_MONGO_PASSWORD"
    ;;
  omada_backup)
    auth_db="admin"
    env_key="OMADA_MONGO_BACKUP_PASSWORD"
    ;;
  *)
    die "USER must be omada or omada_backup"
    ;;
esac

docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" exec -T \
  -e ROTATE_USER="${USER_TO_ROTATE}" \
  -e ROTATE_PASSWORD="${NEW_PASSWORD}" \
  -e ROTATE_AUTH_DB="${auth_db}" \
  mongodb mongosh \
    --username "${MONGO_ROOT_USER}" \
    --password "${MONGO_ROOT_PASSWORD}" \
    --authenticationDatabase admin \
    --eval 'db.getSiblingDB(process.env.ROTATE_AUTH_DB).updateUser(process.env.ROTATE_USER, { pwd: process.env.ROTATE_PASSWORD })'

tmp_file="$(mktemp)"
awk -v key="${env_key}" -v value="${NEW_PASSWORD}" '
  BEGIN { updated = 0 }
  $0 ~ "^" key "=" {
    print key "=" value
    updated = 1
    next
  }
  { print }
  END {
    if (!updated) {
      print key "=" value
    }
  }
' "${ENV_FILE}" > "${tmp_file}"
install -m 0600 "${tmp_file}" "${ENV_FILE}"
rm -f "${tmp_file}"

docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" restart omada-controller
echo "OK: rotated ${USER_TO_ROTATE} password and restarted controller"
