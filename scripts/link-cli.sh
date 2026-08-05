#!/usr/bin/env bash
# Linka o comando `labafero` (packages/cli) no bin global do pnpm, pra poder
# rodar `labafero override:build` de qualquer diretório em vez de
# `node packages/cli/bin/labafero.js override:build`. Idempotente.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI_BIN="${REPO_ROOT}/packages/cli/bin/labafero.js"
GLOBAL_BIN_DIR="$(pnpm bin -g)"

if [[ ! -x "${CLI_BIN}" ]]; then
  echo "Não encontrei ${CLI_BIN} executável — rode 'pnpm install' na raiz primeiro." >&2
  exit 1
fi

mkdir -p "${GLOBAL_BIN_DIR}"
ln -sf "${CLI_BIN}" "${GLOBAL_BIN_DIR}/labafero"

echo "Linkado: ${GLOBAL_BIN_DIR}/labafero -> ${CLI_BIN}"
if ! command -v labafero >/dev/null 2>&1; then
  echo "AVISO: ${GLOBAL_BIN_DIR} não parece estar no PATH. Adicione ao seu shell profile." >&2
  exit 0
fi
echo "Pronto. Teste com: labafero override:build"
