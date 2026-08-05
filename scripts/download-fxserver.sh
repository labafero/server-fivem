#!/usr/bin/env bash
# Baixa o build recomendado do FXServer (Linux) e extrai em server/.
# txAdmin já vem incluso no artefato — não precisa de instalação separada.
#
# A doc do QBCore (qbcore.net/docs/installation/linux) sugere baixar direto
# de .../build_proot_linux/master/fx.tar.xz, mas esse link fixo dá 404 — os
# builds ficam em subpastas versionadas. Resolvemos a build "recommended"
# dinamicamente via API oficial do FiveM (changelogs-live.fivem.net), que é
# a mesma fonte que o txAdmin usa para checar updates.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_DIR="${REPO_ROOT}/server"
CHANGELOG_API="https://changelogs-live.fivem.net/api/changelog/versions/linux/server"

if [[ -x "${SERVER_DIR}/run.sh" && "${1:-}" != "--force" ]]; then
  echo "FXServer já está presente em ${SERVER_DIR} (use --force para rebaixar)."
  exit 0
fi

echo "Resolvendo build recomendada via ${CHANGELOG_API}..."
ARTIFACT_URL="$(curl -fsSL "${CHANGELOG_API}" | grep -o '"recommended_download"[[:space:]]*:[[:space:]]*"[^"]*"' | sed -E 's/.*"(https[^"]+)"/\1/')"

if [[ -z "${ARTIFACT_URL}" ]]; then
  echo "Não foi possível resolver a URL da build recomendada. Verifique ${CHANGELOG_API} manualmente." >&2
  exit 1
fi

mkdir -p "${SERVER_DIR}"
TMP_ARCHIVE="$(mktemp -t fx-XXXXXX.tar.xz)"
trap 'rm -f "${TMP_ARCHIVE}"' EXIT

echo "Baixando build recomendado do FXServer (${ARTIFACT_URL})..."
wget -q --show-progress -O "${TMP_ARCHIVE}" "${ARTIFACT_URL}"

echo "Extraindo em ${SERVER_DIR}..."
tar -xf "${TMP_ARCHIVE}" -C "${SERVER_DIR}"
chmod +x "${SERVER_DIR}/run.sh"

echo "FXServer pronto em ${SERVER_DIR}."
echo "Próximo passo: crie server/server.cfg (ver server/server.cfg.example) e rode ./run.sh +exec server.cfg"
echo "txAdmin sobe automaticamente no primeiro start (porta 40120)."
