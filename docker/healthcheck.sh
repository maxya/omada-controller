#!/usr/bin/env bash
set -euo pipefail

port="${OMADA_MANAGE_HTTPS_PORT:-8043}"
curl -fsS -k --max-time 5 -o /dev/null "https://127.0.0.1:${port}/login"

