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

  local mongo_ports controller_network_mode
  mongo_ports="$(yq -r '.services.mongodb.ports // [] | length' "${COMPOSE_FILE}")"
  [[ "${mongo_ports}" == "0" ]] || die "host-mode MongoDB must not publish host ports"

  controller_network_mode="$(yq -r '.services."omada-controller".network_mode' "${COMPOSE_FILE}")"
  [[ "${controller_network_mode}" == "host" ]] || die "host-mode controller must use network_mode: host"
}

check_ports() {
  local ports=(
    "${OMADA_MANAGE_HTTP_PORT:-8088}"
    "${OMADA_MANAGE_HTTPS_PORT:-8043}"
    "${OMADA_PORTAL_HTTPS_PORT:-8843}"
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

ip_to_int() {
  local ip="$1"
  local a b c d
  IFS=. read -r a b c d <<< "${ip}"

  for octet in "${a}" "${b}" "${c}" "${d}"; do
    [[ "${octet}" =~ ^[0-9]+$ ]] || return 1
    (( 10#${octet} >= 0 && 10#${octet} <= 255 )) || return 1
  done

  echo $(( (10#${a} << 24) + (10#${b} << 16) + (10#${c} << 8) + 10#${d} ))
}

cidr_bounds() {
  local cidr="$1"
  local ip="${cidr%/*}"
  local prefix="${cidr#*/}"
  local ip_int mask network broadcast

  [[ "${cidr}" == */* ]] || return 1
  [[ "${prefix}" =~ ^[0-9]+$ ]] || return 1
  (( prefix >= 0 && prefix <= 32 )) || return 1

  ip_int="$(ip_to_int "${ip}")" || return 1
  if (( prefix == 0 )); then
    mask=0
  else
    mask=$(( (0xffffffff << (32 - prefix)) & 0xffffffff ))
  fi
  network=$(( ip_int & mask ))
  broadcast=$(( network | (0xffffffff ^ mask) ))

  printf '%s %s\n' "${network}" "${broadcast}"
}

cidrs_overlap() {
  local left="$1"
  local right="$2"
  local left_start left_end right_start right_end

  read -r left_start left_end < <(cidr_bounds "${left}") || return 1
  read -r right_start right_end < <(cidr_bounds "${right}") || return 1

  (( left_start <= right_end && right_start <= left_end ))
}

check_docker_network_subnet() {
  local target_subnet="${OMADA_MONGO_SUBNET:-172.28.0.0/24}"
  local mongo_ip="${OMADA_MONGO_IPV4:-172.28.0.10}"
  local target_start target_end mongo_ip_int

  read -r target_start target_end < <(cidr_bounds "${target_subnet}") || die "OMADA_MONGO_SUBNET must be a valid IPv4 CIDR"
  mongo_ip_int="$(ip_to_int "${mongo_ip}")" || die "OMADA_MONGO_IPV4 must be a valid IPv4 address"
  (( mongo_ip_int >= target_start && mongo_ip_int <= target_end )) || die "OMADA_MONGO_IPV4 must be inside OMADA_MONGO_SUBNET"

  local network_id network_name subnet
  while IFS= read -r network_id; do
    [[ -n "${network_id}" ]] || continue
    network_name="$(docker network inspect --format '{{.Name}}' "${network_id}" 2>/dev/null || true)"
    while IFS= read -r subnet; do
      [[ -n "${subnet}" ]] || continue
      if cidrs_overlap "${target_subnet}" "${subnet}"; then
        if [[ "${network_name}" == "omada-controller" && "${subnet}" == "${target_subnet}" ]]; then
          continue
        fi
        die "OMADA_MONGO_SUBNET=${target_subnet} overlaps Docker network ${network_name} (${subnet}); choose another private subnet and matching OMADA_MONGO_IPV4"
      fi
    done < <(docker network inspect --format '{{range .IPAM.Config}}{{println .Subnet}}{{end}}' "${network_id}" 2>/dev/null || true)
  done < <(docker network ls -q)
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
check_docker_network_subnet
check_compose_config

echo "OK: preflight passed"
