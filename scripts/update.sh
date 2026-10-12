#!/usr/bin/env bash
# Atualiza as imagens de todos os serviços e reimplanta os stacks.
# As tags são flutuantes (latest/alpine), então o `docker stack deploy` resolve
# a imagem mais recente a cada execução (--resolve-image always).
#
# Uso:
#   ./scripts/update.sh            # todos os stacks em stacks/
#   ./scripts/update.sh core       # apenas o stack "core"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
STACKS_DIR="${PROJECT_DIR}/stacks"

stacks=("$@")
if [[ ${#stacks[@]} -eq 0 ]]; then
  if [[ ! -d "${STACKS_DIR}" ]]; then
    echo "Nenhum diretório de stacks encontrado: ${STACKS_DIR}" >&2
    exit 1
  fi
  for d in "${STACKS_DIR}"/*/; do
    [[ -d "${d}" ]] || continue
    stacks+=("$(basename "${d}")")
  done
fi

if [[ ${#stacks[@]} -eq 0 ]]; then
  echo "Nenhum stack encontrado para atualizar." >&2
  exit 1
fi

# Extrai as imagens (`image:`) de um docker-stack.yml.
extract_images() {
  local file="$1"
  awk '
    /^[[:space:]]*image:[[:space:]]*[^[:space:]]+/ {
      img = $0
      sub(/^[[:space:]]*image:[[:space:]]*/, "", img)
      sub(/[[:space:]]*$/, "", img)
      if (img !~ /^\$/ && img !~ /@sha256:/) print img
    }
  ' "${file}"
}

overall_failed=0

for stack in "${stacks[@]}"; do
  stack_file="${STACKS_DIR}/${stack}/docker-stack.yml"
  if [[ ! -f "${stack_file}" ]]; then
    echo "✗ Stack file não encontrado: ${stack_file}" >&2
    overall_failed=1
    continue
  fi

  echo ""
  echo "==> Stack: ${stack}"

  echo "  → baixando imagens..."
  while IFS= read -r img; do
    [[ -z "${img}" ]] && continue
    echo "    docker pull ${img}"
    if ! docker pull "${img}"; then
      echo "    ✗ falha ao baixar ${img}" >&2
      overall_failed=1
    fi
  done < <(extract_images "${stack_file}" | sort -u)

  echo "  → reimplantando o stack..."
  if ! "${SCRIPT_DIR}/deploy.sh" "${stack}"; then
    echo "  ✗ falha ao reimplantar o stack ${stack}" >&2
    overall_failed=1
  fi
done

echo ""
if [[ ${overall_failed} -eq 0 ]]; then
  echo "✓ Imagens atualizadas."
else
  echo "✗ Atualização concluída com erros."
fi

exit ${overall_failed}
