#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

[[ -f "${ENV_FILE}" ]] || die "missing .env"

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

[[ -n "${OMADA_URL:-}" ]] || die "OMADA_URL is required"
[[ "${OMADA_URL}" =~ ^https:// ]] || die "OMADA_URL must be HTTPS"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT

curl -fsSL --retry 3 --retry-delay 2 -D "${tmp_dir}/headers.txt" -o "${tmp_dir}/omada.tar.gz" "${OMADA_URL}"

actual_sha="$(sha256sum "${tmp_dir}/omada.tar.gz" | awk '{print $1}')"

if [[ -n "${OMADA_SHA256:-}" ]]; then
  [[ "${actual_sha}" == "${OMADA_SHA256}" ]] || die "SHA256 mismatch: expected ${OMADA_SHA256}, got ${actual_sha}"
  echo "OK: SHA256 verified (${actual_sha})"
else
  manifest="${ROOT_DIR}/release-manifests/omada-${OMADA_VERSION:-unknown}.txt"
  {
    echo "omada_version=${OMADA_VERSION:-unknown}"
    echo "omada_url=${OMADA_URL}"
    echo "artifact_sha256=${actual_sha}"
    grep -Ei '^(etag|last-modified|content-length):' "${tmp_dir}/headers.txt" || true
  } > "${manifest}"
  echo "WARN: no OMADA_SHA256 set; wrote TOFU manifest to ${manifest}" >&2
fi
