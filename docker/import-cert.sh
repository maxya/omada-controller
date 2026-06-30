#!/usr/bin/env bash
set -euo pipefail

OMADA_HOME="${OMADA_HOME:-/opt/omada}"
CERT_DIR="${OMADA_CERT_DIR:-/cert}"
SSL_CERT_NAME="${SSL_CERT_NAME:-tls.crt}"
SSL_KEY_NAME="${SSL_KEY_NAME:-tls.key}"
KEYSTORE_DIR="${OMADA_HOME}/data/keystore"
KEYSTORE_PATH="${KEYSTORE_DIR}/eap.keystore"

if [[ ! -f "${CERT_DIR}/${SSL_KEY_NAME}" && ! -f "${CERT_DIR}/${SSL_CERT_NAME}" ]]; then
  exit 0
fi

if [[ ! -f "${CERT_DIR}/${SSL_KEY_NAME}" || ! -f "${CERT_DIR}/${SSL_CERT_NAME}" ]]; then
  echo "ERROR: both ${CERT_DIR}/${SSL_KEY_NAME} and ${CERT_DIR}/${SSL_CERT_NAME} are required for TLS import" >&2
  exit 1
fi

mkdir -p "${KEYSTORE_DIR}"

tmp_keystore="$(mktemp)"
trap 'rm -f "${tmp_keystore}"' EXIT

openssl pkcs12 -export \
  -inkey "${CERT_DIR}/${SSL_KEY_NAME}" \
  -in "${CERT_DIR}/${SSL_CERT_NAME}" \
  -certfile "${CERT_DIR}/${SSL_CERT_NAME}" \
  -name eap \
  -out "${tmp_keystore}" \
  -passout pass:tplink

install -m 0400 "${tmp_keystore}" "${KEYSTORE_PATH}"
echo "INFO: imported TLS certificate into ${KEYSTORE_PATH}"

