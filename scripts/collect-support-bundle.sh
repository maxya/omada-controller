#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.host.yml"
OUT_DIR="${ROOT_DIR}/support-bundles/$(date -u +%Y%m%dT%H%M%SZ)"

redact() {
  sed -E \
    -e 's/(MONGO[^=]*PASSWORD=).*/\1[REDACTED]/Ig' \
    -e 's/(OMADA_MONGO[^=]*PASSWORD=).*/\1[REDACTED]/Ig' \
    -e 's/([^=]*(SECRET|TOKEN)[^=]*=).*/\1[REDACTED]/Ig' \
    -e 's#(EAP_MONGOD_URI=).*#\1[REDACTED]#Ig' \
    -e 's#(OMADA_MONGODB_URI=).*#\1[REDACTED]#Ig' \
    -e 's#(mongodb://[^:/@]+:)[^@]+(@)#\1[REDACTED]\2#g' \
    -e 's#(-D[^ =]*password[^ =]*=)[^ ]+#\1[REDACTED]#Ig'
}

mkdir -p "${OUT_DIR}"

{
  echo "generated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "project_dir=${ROOT_DIR}"
  docker version 2>&1 || true
  docker compose version 2>&1 || true
} > "${OUT_DIR}/versions.txt"

if [[ -f "${ENV_FILE}" ]]; then
  redact < "${ENV_FILE}" > "${OUT_DIR}/env.redacted"
fi

docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" config 2>&1 | redact > "${OUT_DIR}/compose-config.redacted" || true
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" ps > "${OUT_DIR}/compose-ps.txt" 2>&1 || true
docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" logs --tail=250 2>&1 | redact > "${OUT_DIR}/compose-logs.redacted" || true

for service in mongodb omada-controller; do
  container_id="$(docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" ps -q "${service}" 2>/dev/null || true)"
  if [[ -n "${container_id}" ]]; then
    docker inspect "${container_id}" 2>&1 | redact > "${OUT_DIR}/${service}-inspect.redacted" || true
  fi
done

tar -C "$(dirname "${OUT_DIR}")" -czf "${OUT_DIR}.tar.gz" "$(basename "${OUT_DIR}")"
echo "Support bundle written to ${OUT_DIR}.tar.gz"
