#!/usr/bin/env bats

setup() {
  TMP_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${TMP_DIR}"
}

@test "version guard allows newer image over older data" {
  echo "6.2.10.18" > "${TMP_DIR}/image"
  mkdir -p "${TMP_DIR}/data"
  echo "6.2.10.17" > "${TMP_DIR}/data/.last_started_version"

  run ./docker/version-guard.sh "${TMP_DIR}/image" "${TMP_DIR}/data/.last_started_version"

  [ "$status" -eq 0 ]
  [ "$(cat "${TMP_DIR}/data/.last_started_version")" = "6.2.10.18" ]
}

@test "version guard rejects older image against newer data" {
  echo "6.2.9.20" > "${TMP_DIR}/image"
  mkdir -p "${TMP_DIR}/data"
  echo "6.2.10.17" > "${TMP_DIR}/data/.last_started_version"

  run ./docker/version-guard.sh "${TMP_DIR}/image" "${TMP_DIR}/data/.last_started_version"

  [ "$status" -ne 0 ]
  [[ "$output" == *"refusing to start"* ]]
}

@test "version guard allows same version" {
  echo "6.2.10.17" > "${TMP_DIR}/image"
  mkdir -p "${TMP_DIR}/data"
  echo "6.2.10.17" > "${TMP_DIR}/data/.last_started_version"

  run ./docker/version-guard.sh "${TMP_DIR}/image" "${TMP_DIR}/data/.last_started_version"

  [ "$status" -eq 0 ]
}


@test "render-properties does not fuse a key onto a file with no trailing newline" {
  # TP-Link ships omada.properties without a trailing newline. Appending to it
  # naively produces "client.cluster.sync.interval.second=30web.config.override=false",
  # which aborts controller startup with a NumberFormatException.
  printf 'client.cluster.sync.interval.second=30' > "${TMP_DIR}/omada.properties"

  OMADA_PROPERTIES_FILE="${TMP_DIR}/omada.properties" \
    OMADA_MONGODB_URI="mongodb://omada:pw@127.0.0.1:27017/omada?authSource=omada" \
    run ./docker/render-properties.sh

  [ "$status" -eq 0 ]
  [ "$(grep -c '^client.cluster.sync.interval.second=30$' "${TMP_DIR}/omada.properties")" -eq 1 ]
  [ "$(grep -c '^web.config.override=false$' "${TMP_DIR}/omada.properties")" -eq 1 ]
  ! grep -q '30web.config.override' "${TMP_DIR}/omada.properties"
}

@test "render-properties leaves an already newline-terminated file intact" {
  printf 'client.cluster.sync.interval.second=30\n' > "${TMP_DIR}/omada.properties"

  OMADA_PROPERTIES_FILE="${TMP_DIR}/omada.properties" \
    OMADA_MONGODB_URI="mongodb://omada:pw@127.0.0.1:27017/omada?authSource=omada" \
    run ./docker/render-properties.sh

  [ "$status" -eq 0 ]
  [ "$(grep -c '^client.cluster.sync.interval.second=30$' "${TMP_DIR}/omada.properties")" -eq 1 ]
  [ "$(grep -c '^web.config.override=false$' "${TMP_DIR}/omada.properties")" -eq 1 ]
  # No stray blank line should be introduced when the file was already terminated.
  [ "$(grep -c '^$' "${TMP_DIR}/omada.properties")" -eq 0 ]
}
