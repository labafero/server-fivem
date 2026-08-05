#!/usr/bin/env bash
# Baixa o build recomendado do FXServer (Linux) e extrai em server/.
# txAdmin já vem incluso no artefato — não precisa de instalação separada.
# Fonte: https://qbcore.net/docs/installation/linux (Step 4/5)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_DIR="${REPO_ROOT}/server"
ARTIFACT_URL="https://runtime.fivem.net/artifacts/fivem/build_proot_linux/master/fx.tar.xz"

if [[ -x "${SERVER_DIR}/run.sh" && "${1:-}" != "--force" ]]; then
  echo "FXServer já está presente em ${SERVER_DIR} (use --force para rebaixar)."
  exit 0
fi

mkdir -p "${SERVER_DIR}"
TMP_ARCHIVE="$(mktemp -t fx-XXXXXX.tar.xz)"
trap 'rm -f "${TMP_ARCHIVE}"' EXIT

echo "Baixando build recomendado do FXServer..."
wget -q --show-progress -O "${TMP_ARCHIVE}" "${ARTIFACT_URL}"

echo "Extraindo em ${SERVER_DIR}..."
tar -xf "${TMP_ARCHIVE}" -C "${SERVER_DIR}"
chmod +x "${SERVER_DIR}/run.sh"

echo "FXServer pronto em ${SERVER_DIR}."
echo "Próximo passo: crie server/server.cfg (ver server/server.cfg.example) e rode ./run.sh +exec server.cfg"
echo "txAdmin sobe automaticamente no primeiro start (porta 40120)."
