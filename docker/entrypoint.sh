#!/usr/bin/env bash
set -euo pipefail

OMADA_HOME="${OMADA_HOME:-/opt/omada}"

# shellcheck source=/usr/local/bin/version-guard.sh
source /usr/local/bin/version-guard.sh

restore_properties() {
  mkdir -p "${OMADA_HOME}/properties"

  if [[ -d "${OMADA_HOME}/properties.defaults" ]]; then
    while IFS= read -r -d '' default_file; do
      local target
      target="${OMADA_HOME}/properties/$(basename "${default_file}")"
      if [[ ! -f "${target}" ]]; then
        cp "${default_file}" "${target}"
      fi
    done < <(find "${OMADA_HOME}/properties.defaults" -maxdepth 1 -type f -print0)
  fi
}

prepare_directories() {
  mkdir -p "${OMADA_HOME}/data" "${OMADA_HOME}/logs"

  if [[ ! -d "${OMADA_HOME}/data/html" && -f "${OMADA_HOME}/data-html.tar.gz" ]]; then
    tar -xzf "${OMADA_HOME}/data-html.tar.gz" -C "${OMADA_HOME}/data"
  fi

  mkdir -p "${OMADA_HOME}/data/pdf"
}

warn_about_backups() {
  if [[ ! -d "${OMADA_HOME}/data/autobackup" ]]; then
    echo "WARN: Omada automatic backups do not appear to be configured. Enable them in the controller UI after first login."
  fi
}

build_java_command() {
  local min_heap="${JAVA_MIN_HEAP:-128m}"
  local max_heap="${JAVA_MAX_HEAP:-1024m}"

  JAVA_CMD=(
    java
    -server
    "-Xms${min_heap}"
    "-Xmx${max_heap}"
    -XX:MaxHeapFreeRatio=60
    -XX:MinHeapFreeRatio=30
    -XX:+HeapDumpOnOutOfMemoryError
    "-XX:HeapDumpPath=${OMADA_HOME}/logs/java_heapdump.hprof"
    -Djava.awt.headless=true
    -cp "${OMADA_HOME}/lib/*:${OMADA_HOME}/properties"
    com.tplink.smb.omada.starter.OmadaLinuxMain
  )
}

restore_properties
prepare_directories
/usr/local/bin/render-properties.sh
/usr/local/bin/import-cert.sh
downgrade_guard "${OMADA_HOME}/IMAGE_OMADA_VER.txt" "${OMADA_HOME}/data/.last_started_version"
warn_about_backups
build_java_command

echo "INFO: starting Omada controller"
exec "${JAVA_CMD[@]}"

