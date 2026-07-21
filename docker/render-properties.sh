#!/usr/bin/env bash
set -euo pipefail

OMADA_HOME="${OMADA_HOME:-/opt/omada}"
PROPERTIES_FILE="${OMADA_PROPERTIES_FILE:-${OMADA_HOME}/properties/omada.properties}"

redact_mongo_uri() {
  sed -E 's#(mongodb://[^:/@]+:)[^@]+(@)#\1*****\2#g' <<< "$1"
}

ensure_trailing_newline() {
  local file="$1"

  # A properties file whose last byte is not a newline would fuse the next
  # appended key onto its final value. TP-Link ships omada.properties that way.
  if [[ -s "${file}" ]] && [[ -n "$(tail -c 1 "${file}")" ]]; then
    printf '\n' >> "${file}"
  fi
}

set_property() {
  local key="$1"
  local value="$2"
  local display_value="${3:-$2}"
  local escaped_value

  escaped_value="$(printf '%s' "${value}" | sed -e 's/[\/&]/\\&/g')"

  if grep -q "^${key}=" "${PROPERTIES_FILE}"; then
    sed -i "s/^${key}=.*/${key}=${escaped_value}/" "${PROPERTIES_FILE}"
  else
    ensure_trailing_newline "${PROPERTIES_FILE}"
    printf '%s=%s\n' "${key}" "${value}" >> "${PROPERTIES_FILE}"
  fi

  echo "INFO: ${key}=${display_value}"
}

validate_port() {
  local name="$1"
  local value="$2"

  [[ "${value}" =~ ^[0-9]+$ ]] || {
    echo "ERROR: ${name} must be numeric" >&2
    exit 1
  }

  if (( value < 1 || value > 65535 )); then
    echo "ERROR: ${name} must be between 1 and 65535" >&2
    exit 1
  fi

  if (( value < 1024 )) && [[ -r /proc/sys/net/ipv4/ip_unprivileged_port_start ]]; then
    local unprivileged_start
    unprivileged_start="$(cat /proc/sys/net/ipv4/ip_unprivileged_port_start)"
    if (( unprivileged_start > value )); then
      echo "ERROR: ${name}=${value} requires ip_unprivileged_port_start <= ${value}" >&2
      exit 1
    fi
  fi
}

[[ -f "${PROPERTIES_FILE}" ]] || {
  echo "ERROR: missing Omada properties file: ${PROPERTIES_FILE}" >&2
  exit 1
}

OMADA_MONGODB_URI="${OMADA_MONGODB_URI:-}"
[[ -n "${OMADA_MONGODB_URI}" ]] || {
  echo "ERROR: OMADA_MONGODB_URI is required" >&2
  exit 1
}

OMADA_MANAGE_HTTP_PORT="${OMADA_MANAGE_HTTP_PORT:-8088}"
OMADA_MANAGE_HTTPS_PORT="${OMADA_MANAGE_HTTPS_PORT:-8043}"
OMADA_PORTAL_HTTP_PORT="${OMADA_PORTAL_HTTP_PORT:-8088}"
OMADA_PORTAL_HTTPS_PORT="${OMADA_PORTAL_HTTPS_PORT:-8843}"
OMADA_UPGRADE_HTTPS_PORT="${OMADA_UPGRADE_HTTPS_PORT:-8043}"
OMADA_WEB_CONFIG_OVERRIDE="${OMADA_WEB_CONFIG_OVERRIDE:-false}"

for port_var in OMADA_MANAGE_HTTP_PORT OMADA_MANAGE_HTTPS_PORT OMADA_PORTAL_HTTP_PORT OMADA_PORTAL_HTTPS_PORT OMADA_UPGRADE_HTTPS_PORT; do
  validate_port "${port_var}" "${!port_var}"
done

case "${OMADA_WEB_CONFIG_OVERRIDE}" in
  true|false) ;;
  *)
    echo "ERROR: OMADA_WEB_CONFIG_OVERRIDE must be true or false" >&2
    exit 1
    ;;
esac

set_property "manage.http.port" "${OMADA_MANAGE_HTTP_PORT}"
set_property "manage.https.port" "${OMADA_MANAGE_HTTPS_PORT}"
set_property "portal.http.port" "${OMADA_PORTAL_HTTP_PORT}"
set_property "portal.https.port" "${OMADA_PORTAL_HTTPS_PORT}"
set_property "upgrade.https.port" "${OMADA_UPGRADE_HTTPS_PORT}"
set_property "web.config.override" "${OMADA_WEB_CONFIG_OVERRIDE}"
set_property "mongo.external" "true"
set_property "eap.mongod.uri" "${OMADA_MONGODB_URI}" "$(redact_mongo_uri "${OMADA_MONGODB_URI}")"

