#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"
COMPOSE_FILE="${ROOT_DIR}/compose/docker-compose.host.yml"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

warn() {
  echo "WARN: $*" >&2
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

load_env() {
  [[ -f "${ENV_FILE}" ]] || die "missing .env; copy .env.example to .env and edit it"
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
}

require_var() {
  local name="$1"
  local value="${!name:-}"
  [[ -n "${value}" ]] || die "${name} is required in .env"
}

check_docker() {
  need_cmd docker
  docker compose version >/dev/null 2>&1 || die "Docker Compose v2 is required"
}

check_yq() {
  need_cmd yq

  local bind_ip
  bind_ip="$(yq -r '.services.mongodb.command[]' "${COMPOSE_FILE}" | paste -sd ' ' -)"
  [[ "${bind_ip}" == *"--bind_ip 127.0.0.1"* ]] || die "host-mode MongoDB must explicitly include --bind_ip 127.0.0.1"
}

check_ports() {
  local ports=(
    "${OMADA_MANAGE_HTTP_PORT:-8088}"
    "${OMADA_MANAGE_HTTPS_PORT:-8043}"
    "${OMADA_PORTAL_HTTPS_PORT:-8843}"
    27017
    29811
    29812
    29813
    29814
    29815
    29816
    29817
  )

  if ! command -v ss >/dev/null 2>&1; then
    warn "ss not found; skipping port conflict checks"
    return
  fi

  for port in "${ports[@]}"; do
    if ss -ltn "sport = :${port}" | awk 'NR > 1 {found=1} END {exit !found}'; then
      die "TCP port ${port} is already listening on the host"
    fi
  done
}

check_env_values() {
  require_var MONGO_ROOT_USER
  require_var MONGO_ROOT_PASSWORD
  require_var OMADA_MONGO_PASSWORD
  require_var OMADA_MONGO_BACKUP_PASSWORD

  if [[ -z "${OMADA_ARTIFACT_PATH:-}" ]]; then
    require_var OMADA_URL
    case "${OMADA_URL}" in
      https://*tp-link.com*|https://*tplinkcloud.com*|https://*omadanetworks.com*)
        ;;
      *)
        die "OMADA_URL must be an official TP-Link/Omada HTTPS download URL"
        ;;
    esac
  elif [[ ! -f "${ROOT_DIR}/artifacts/${OMADA_ARTIFACT_PATH}" && ! -f "${OMADA_ARTIFACT_PATH}" ]]; then
    die "OMADA_ARTIFACT_PATH does not point to an existing staged artifact"
  fi

  for value in "${MONGO_ROOT_PASSWORD:-}" "${OMADA_MONGO_PASSWORD:-}" "${OMADA_MONGO_BACKUP_PASSWORD:-}"; do
    case "${value}" in
      change-this-*)
        die "replace placeholder passwords in .env"
        ;;
    esac
  done
}

check_compose_config() {
  docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" config >/dev/null
}

load_env
check_docker
check_yq
check_env_values
"${ROOT_DIR}/scripts/check-cpu-mongodb8.sh"
check_ports
check_compose_config

echo "OK: preflight passed"

