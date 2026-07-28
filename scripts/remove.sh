#!/usr/bin/env bash
set -euo pipefail

STACK_NAME="${1:-core}"

docker stack rm "${STACK_NAME}"
