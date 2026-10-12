#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="${1:-core}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
STACK_FILE="${PROJECT_DIR}/stacks/${STACK_NAME}/docker-stack.yml"

if [[ ! -f "${STACK_FILE}" ]]; then
  echo "Stack file not found: ${STACK_FILE}" >&2
  exit 1
fi

export STACK_NAME
export NGINX_DEFAULT_CONF_HASH="$(sha256sum "${PROJECT_DIR}/configs/nginx/default.conf" | cut -d ' ' -f1 | cut -c1-32)"
export NGINX_APPS_WILDCARD_CONF_HASH="$(sha256sum "${PROJECT_DIR}/configs/nginx/apps.wildcard.arpa.conf" | cut -d ' ' -f1 | cut -c1-32)"

docker stack deploy --with-registry-auth -c "${STACK_FILE}" "${STACK_NAME}"
