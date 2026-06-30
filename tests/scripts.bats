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

