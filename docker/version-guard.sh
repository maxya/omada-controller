#!/usr/bin/env bash

version_is_lower() {
  local image_version="$1"
  local data_version="$2"
  local lowest

  [[ -n "${image_version}" ]] || return 1
  [[ -n "${data_version}" ]] || return 1
  [[ "${image_version}" != "${data_version}" ]] || return 1

  lowest="$(printf '%s\n%s\n' "${image_version}" "${data_version}" | sort -V | head -n 1)"
  [[ "${lowest}" == "${image_version}" ]]
}

downgrade_guard() {
  local image_version_file="$1"
  local last_started_file="$2"
  local image_version=""
  local last_started_version=""

  image_version="$(tr -d '[:space:]' < "${image_version_file}")"

  if [[ -f "${last_started_file}" ]]; then
    last_started_version="$(tr -d '[:space:]' < "${last_started_file}")"
  fi

  if [[ -n "${last_started_version}" ]] && version_is_lower "${image_version}" "${last_started_version}"; then
    echo "ERROR: refusing to start Omada ${image_version} against data last started by ${last_started_version}" >&2
    echo "ERROR: restore from backup or intentionally remove ${last_started_file} before accepting downgrade risk" >&2
    return 1
  fi

  mkdir -p "$(dirname "${last_started_file}")"
  printf '%s\n' "${image_version}" > "${last_started_file}"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  if [[ "$#" -eq 2 ]]; then
    downgrade_guard "$1" "$2"
  else
    echo "usage: version-guard.sh IMAGE_VERSION_FILE LAST_STARTED_FILE" >&2
    exit 2
  fi
fi

