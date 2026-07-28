#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="${1:-core}"
STACK_FILE="stacks/${STACK_NAME}/docker-stack.yml"

if [[ ! -f "${STACK_FILE}" ]]; then
  echo "Stack file not found: ${STACK_FILE}" >&2
  exit 1
fi

docker stack deploy --with-registry-auth -c "${STACK_FILE}" "${STACK_NAME}"
