#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="${1:-core}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
STACK_FILE="${PROJECT_DIR}/stacks/${STACK_NAME}/docker-stack.yml"
ENV_FILE="${PROJECT_DIR}/stacks/${STACK_NAME}/.env"

if [[ ! -f "${STACK_FILE}" ]]; then
  echo "Stack file not found: ${STACK_FILE}" >&2
  exit 1
fi

if [[ -f "${ENV_FILE}" ]]; then
  while IFS= read -r line || [[ -n "${line}" ]]; do
    [[ "${line}" =~ ^[[:space:]]*(#|$) ]] && continue

    if [[ ! "${line}" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      echo "Invalid entry in ${ENV_FILE}" >&2
      exit 1
    fi

    name="${BASH_REMATCH[1]}"
    value="${BASH_REMATCH[2]}"
    case "${value}" in
      \"*\") value="${value:1:${#value}-2}" ;;
      \'*\') value="${value:1:${#value}-2}" ;;
    esac
    export "${name}=${value}"
  done < "${ENV_FILE}"
fi

STACK_NAME="${1:-core}"
export STACK_NAME
export NGINX_DEFAULT_CONF_HASH="$(sha256sum "${PROJECT_DIR}/configs/nginx/default.conf" | cut -d ' ' -f1 | cut -c1-32)"
export NGINX_APPS_WILDCARD_CONF_HASH="$(sha256sum "${PROJECT_DIR}/configs/nginx/apps.wildcard.arpa.conf" | cut -d ' ' -f1 | cut -c1-32)"

docker stack deploy --with-registry-auth -c "${STACK_FILE}" "${STACK_NAME}"
