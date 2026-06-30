#!/usr/bin/env bash
set -euo pipefail

arch="$(uname -m)"

case "${arch}" in
  x86_64|amd64)
    if grep -qi '^flags.* avx' /proc/cpuinfo; then
      echo "OK: CPU exposes AVX for MongoDB 8"
    else
      echo "ERROR: MongoDB 8 on amd64 requires AVX CPU support" >&2
      exit 1
    fi
    ;;
  aarch64|arm64)
    echo "WARN: arm64 is not a supported v1 target; verify armv8.2-a before using MongoDB 8" >&2
    ;;
  *)
    echo "ERROR: unsupported architecture for this v1 stack: ${arch}" >&2
    exit 1
    ;;
esac

