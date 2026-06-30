#!/usr/bin/env bash
set -euo pipefail

OMADA_HOME="${OMADA_HOME:-/opt/omada}"
OMADA_VERSION="${OMADA_VERSION:-}"
OMADA_URL="${OMADA_URL:-}"
OMADA_SHA256="${OMADA_SHA256:-}"
OMADA_ARTIFACT_PATH="${OMADA_ARTIFACT_PATH:-}"
ARTIFACT_DIR="/tmp/omada-artifacts"
WORK_DIR="/tmp/omada-install"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

log() {
  echo "INFO: $*"
}

copy_staged_artifact() {
  local candidate=""

  if [[ -n "${OMADA_ARTIFACT_PATH}" ]]; then
    if [[ "${OMADA_ARTIFACT_PATH}" = /* && -f "${OMADA_ARTIFACT_PATH}" ]]; then
      candidate="${OMADA_ARTIFACT_PATH}"
    elif [[ -f "${ARTIFACT_DIR}/${OMADA_ARTIFACT_PATH}" ]]; then
      candidate="${ARTIFACT_DIR}/${OMADA_ARTIFACT_PATH}"
    fi
  fi

  if [[ -n "${candidate}" ]]; then
    log "Using staged Omada artifact: ${candidate}"
    cp "${candidate}" "${WORK_DIR}/omada.tar.gz"
    return 0
  fi

  return 1
}

download_artifact() {
  [[ -n "${OMADA_URL}" ]] || die "OMADA_URL is required unless OMADA_ARTIFACT_PATH points to a staged artifact"
  [[ "${OMADA_URL}" =~ ^https:// ]] || die "OMADA_URL must be an HTTPS URL"

  case "${OMADA_URL}" in
    *tp-link.com*|*tplinkcloud.com*|*omadanetworks.com*)
      ;;
    *)
      die "OMADA_URL must point to a TP-Link/Omada download host"
      ;;
  esac

  log "Downloading Omada artifact from ${OMADA_URL}"
  curl -fsSL --retry 3 --retry-delay 2 -D "${WORK_DIR}/headers.txt" -o "${WORK_DIR}/omada.tar.gz" "${OMADA_URL}"
}

verify_artifact() {
  if [[ -n "${OMADA_SHA256}" ]]; then
    log "Verifying Omada artifact SHA256"
    printf '%s  %s\n' "${OMADA_SHA256}" "${WORK_DIR}/omada.tar.gz" | sha256sum -c -
  else
    log "No OMADA_SHA256 provided; recording trust-on-first-use metadata inside the image"
    {
      echo "omada_version=${OMADA_VERSION}"
      echo "omada_url=${OMADA_URL}"
      echo "artifact_sha256=$(sha256sum "${WORK_DIR}/omada.tar.gz" | awk '{print $1}')"
      if [[ -f "${WORK_DIR}/headers.txt" ]]; then
        grep -Ei '^(etag|last-modified|content-length):' "${WORK_DIR}/headers.txt" || true
      fi
    } > "${WORK_DIR}/release-manifest.txt"
  fi
}

append_property_if_missing() {
  local key="$1"
  local value="$2"
  local file="${OMADA_HOME}/properties/omada.properties"

  if ! grep -q "^${key}=" "${file}"; then
    printf '%s=%s\n' "${key}" "${value}" >> "${file}"
  fi
}

install_tree() {
  mkdir -p "${OMADA_HOME}"
  tar -xzf "${WORK_DIR}/omada.tar.gz" -C "${WORK_DIR}/extract"

  local source_dir=""
  if compgen -G "${WORK_DIR}/extract/Omada_Network_Application_*" > /dev/null; then
    source_dir="$(find "${WORK_DIR}/extract" -maxdepth 1 -type d -name 'Omada_Network_Application_*' | head -n 1)"
  elif compgen -G "${WORK_DIR}/extract/Omada_SDN_Controller_*" > /dev/null; then
    source_dir="$(find "${WORK_DIR}/extract" -maxdepth 1 -type d -name 'Omada_SDN_Controller_*' | head -n 1)"
  else
    die "Could not find Omada application directory in artifact"
  fi

  for name in bin data lib properties install.sh uninstall.sh; do
    [[ -e "${source_dir}/${name}" ]] || die "Expected Omada artifact member is missing: ${name}"
    cp -a "${source_dir}/${name}" "${OMADA_HOME}/"
  done

  mkdir -p "${OMADA_HOME}/logs"

  if [[ -d "${OMADA_HOME}/data/html" ]]; then
    tar -C "${OMADA_HOME}/data" -czf "${OMADA_HOME}/data-html.tar.gz" html
  fi

  append_property_if_missing "web.config.override" "false"
  append_property_if_missing "mongo.external" "true"
  append_property_if_missing "eap.mongod.uri" "mongodb://127.0.0.1:27017/omada?authSource=omada"

  cp -a "${OMADA_HOME}/properties" "${OMADA_HOME}/properties.defaults"
  echo "${OMADA_VERSION}" > "${OMADA_HOME}/IMAGE_OMADA_VER.txt"

  if [[ -f "${WORK_DIR}/release-manifest.txt" ]]; then
    cp "${WORK_DIR}/release-manifest.txt" "${OMADA_HOME}/RELEASE_MANIFEST.txt"
  fi
}

[[ -n "${OMADA_VERSION}" ]] || die "OMADA_VERSION is required"

rm -rf "${WORK_DIR}"
mkdir -p "${WORK_DIR}/extract"

copy_staged_artifact || download_artifact
verify_artifact
install_tree

log "Installed Omada ${OMADA_VERSION} into ${OMADA_HOME}"
