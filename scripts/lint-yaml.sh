#!/usr/bin/env bash
set -euo pipefail

# Parse-check every Compose YAML file.
#
# Two incompatible tools are both called "yq":
#   - kislyuk/yq  (Python wrapper around jq; shipped as Arch's "yq" package)
#       syntax: yq '<jq filter>' FILE
#   - mikefarah/yq (Go; shipped as Arch's "go-yq" package)
#       syntax: yq e '<expr>' FILE
# Both report version numbers in the 4.x range, so detect by the vendor string
# rather than the version, and fall back to the jq-style flavor.

cd "$(dirname "${BASH_SOURCE[0]}")/.."

files=(compose/*.yml compose/profiles/*.yml)

if ! command -v yq >/dev/null 2>&1; then
  echo "WARN: yq not installed; skipped YAML parse"
  exit 0
fi

if yq --version 2>&1 | grep -qi mikefarah; then
  flavor=go
else
  flavor=jq
fi

if [ "${flavor}" = jq ] && ! command -v jq >/dev/null 2>&1; then
  echo "WARN: python yq requires jq, which is not installed; skipped YAML parse"
  exit 0
fi

rc=0
checked=0
for f in "${files[@]}"; do
  [ -e "${f}" ] || continue
  checked=$((checked + 1))
  case "${flavor}" in
    go) yq e '.' "${f}" >/dev/null || { echo "FAIL: ${f} did not parse"; rc=1; } ;;
    jq) yq '.' "${f}" >/dev/null || { echo "FAIL: ${f} did not parse"; rc=1; } ;;
  esac
done

if [ "${rc}" -eq 0 ]; then
  echo "OK: ${checked} YAML files parsed (yq flavor: ${flavor})"
fi

exit "${rc}"
