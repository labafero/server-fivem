#!/usr/bin/env bash
# Instala o recipe oficial do QBCore (qbcore-framework/txAdminRecipe) em
# server/resources/, importa o schema no banco e atualiza server/server.cfg.
# Idempotente: pula resources já clonados, não duplica linhas no server.cfg.
#
# Fonte: https://github.com/qbcore-framework/txAdminRecipe (qbcore.yaml)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVER_DIR="${REPO_ROOT}/server"
RES_DIR="${SERVER_DIR}/resources"
CFG_FILE="${SERVER_DIR}/server.cfg"
ENV_FILE="${REPO_ROOT}/.env"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

if [[ ! -d "${SERVER_DIR}" ]]; then
  echo "server/ não existe — rode scripts/download-fxserver.sh primeiro." >&2
  exit 1
fi
if [[ ! -f "${CFG_FILE}" ]]; then
  echo "server/server.cfg não existe — crie a partir de server.cfg.example primeiro." >&2
  exit 1
fi

clone_resource() {
  local category="$1" name="$2" ref="$3" url="$4"
  local dest="${RES_DIR}/${category}/${name}"
  if [[ -d "${dest}" && -n "$(ls -A "${dest}" 2>/dev/null)" ]]; then
    echo "skip (já existe): ${category}/${name}"
    return
  fi
  echo "clonando ${category}/${name}..."
  mkdir -p "$(dirname "${dest}")"
  git clone --quiet --depth 1 --branch "${ref}" "${url}" "${dest}"
  rm -rf "${dest}/.git"
}

# --- Base cfx (mapmanager, chat, spawnmanager, sessionmanager, basic-gamemode, hardcap, baseevents) ---
if [[ ! -d "${RES_DIR}/[cfx-default]" ]]; then
  echo "clonando cfx-server-data..."
  git clone --quiet --depth 1 https://github.com/citizenfx/cfx-server-data "${TMP_DIR}/cfx-server-data"
  cp -r "${TMP_DIR}/cfx-server-data/resources" "${RES_DIR}/[cfx-default]"
  rm -rf "${RES_DIR}/[cfx-default]/[gameplay]/chat"
else
  echo "skip (já existe): [cfx-default]"
fi

# --- oxmysql (release zip) ---
if [[ ! -d "${RES_DIR}/[standalone]/oxmysql" ]]; then
  echo "baixando oxmysql..."
  mkdir -p "${RES_DIR}/[standalone]"
  curl -fsSL -o "${TMP_DIR}/oxmysql.zip" \
    "https://github.com/overextended/oxmysql/releases/download/v2.14.1/oxmysql.zip"
  unzip -q "${TMP_DIR}/oxmysql.zip" -d "${RES_DIR}/[standalone]"
else
  echo "skip (já existe): [standalone]/oxmysql"
fi

# --- menuv (release zip, sem pasta própria dentro do zip) ---
if [[ ! -d "${RES_DIR}/[standalone]/menuv" ]]; then
  echo "baixando menuv..."
  mkdir -p "${RES_DIR}/[standalone]/menuv"
  curl -fsSL -o "${TMP_DIR}/menuv.zip" \
    "https://github.com/ThymonA/menuv/releases/download/v1.4.1/menuv_v1.4.1.zip"
  unzip -q "${TMP_DIR}/menuv.zip" -d "${RES_DIR}/[standalone]/menuv"
else
  echo "skip (já existe): [standalone]/menuv"
fi

# --- [standalone] (git) ---
clone_resource "[standalone]" bob74_ipl master https://github.com/qbcore-framework/bob74_ipl
clone_resource "[standalone]" safecracker main https://github.com/qbcore-framework/safecracker
clone_resource "[standalone]" screenshot-basic master https://github.com/citizenfx/screenshot-basic
clone_resource "[standalone]" progressbar main https://github.com/qbcore-framework/progressbar
clone_resource "[standalone]" interact-sound master https://github.com/qbcore-framework/interact-sound
clone_resource "[standalone]" connectqueue master https://github.com/qbcore-framework/connectqueue
clone_resource "[standalone]" PolyZone master https://github.com/qbcore-framework/PolyZone

# --- [voice] ---
clone_resource "[voice]" pma-voice main https://github.com/AvarianKnight/pma-voice
clone_resource "[voice]" qb-radio main https://github.com/qbcore-framework/qb-radio

# --- [defaultmaps] ---
clone_resource "[defaultmaps]" hospital_map main https://github.com/qbcore-framework/hospital_map
clone_resource "[defaultmaps]" dealer_map main https://github.com/qbcore-framework/dealer_map
# prison_map fica aninhado em outra pasta [prison_map], igual o recipe oficial
if [[ ! -d "${RES_DIR}/[defaultmaps]/[prison_map]" || -z "$(ls -A "${RES_DIR}/[defaultmaps]/[prison_map]" 2>/dev/null)" ]]; then
  echo "clonando [defaultmaps]/[prison_map]..."
  mkdir -p "${RES_DIR}/[defaultmaps]"
  git clone --quiet --depth 1 --branch main https://github.com/qbcore-framework/prison_map "${RES_DIR}/[defaultmaps]/[prison_map]"
  rm -rf "${RES_DIR}/[defaultmaps]/[prison_map]/.git"
else
  echo "skip (já existe): [defaultmaps]/[prison_map]"
fi

# --- [qb] (framework + jobs + sistemas, todos ref main) ---
QB_RESOURCES=(
  qb-core qb-scoreboard qb-adminmenu qb-multicharacter qb-target
  qb-vehiclesales qb-vehicleshop qb-houserobbery qb-prison qb-hud
  qb-management qb-weed qb-lapraces qb-inventory qb-houses
  qb-garages qb-ambulancejob qb-radialmenu qb-crypto qb-weathersync
  qb-policejob qb-apartments qb-vehiclekeys qb-mechanicjob qb-phone
  qb-vineyard qb-weapons qb-scrapyard qb-towjob qb-streetraces
  qb-storerobbery qb-spawn qb-smallresources qb-recyclejob qb-crafting
  qb-diving qb-cityhall qb-truckrobbery qb-pawnshop qb-minigames
  qb-taxijob qb-busjob qb-newsjob qb-fuel qb-jewelery
  qb-bankrobbery qb-banking qb-clothing qb-hotdogjob qb-doorlock
  qb-garbagejob qb-drugs qb-shops qb-interior qb-menu
  qb-input qb-loading
)
for name in "${QB_RESOURCES[@]}"; do
  clone_resource "[qb]" "${name}" main "https://github.com/qbcore-framework/${name}"
done

# --- Schema do banco ---
if [[ -f "${ENV_FILE}" ]] && grep -q '^QBCORE_DB_PASSWORD=' "${ENV_FILE}"; then
  DB_PASSWORD="$(grep '^QBCORE_DB_PASSWORD=' "${ENV_FILE}" | cut -d= -f2-)"
  echo "importando qbcore.sql no banco..."
  curl -fsSL -o "${TMP_DIR}/qbcore.sql" \
    "https://raw.githubusercontent.com/qbcore-framework/txAdminRecipe/main/qbcore.sql"
  MYSQL_PWD="${DB_PASSWORD}" mysql -u qbcore qbcore < "${TMP_DIR}/qbcore.sql"
  echo "schema importado."
else
  echo "AVISO: .env com QBCORE_DB_PASSWORD não encontrado — rode scripts/setup-db.sh antes. Pulei o import do schema." >&2
fi

# --- server.cfg (idempotente: só insere se ainda não tiver o marcador) ---
if ! grep -q "QBCore (Fase 1)" "${CFG_FILE}"; then
  echo "atualizando server/server.cfg..."
  cat >> "${CFG_FILE}" <<'EOF'

# --- QBCore (Fase 1, via scripts/install-qbcore.sh) ---
# Baseado no server.cfg oficial de https://github.com/qbcore-framework/txAdminRecipe
set steam_webApiKey "none"
sets tags "default, qbcore, qb-core"
sets locale "pt-BR"
sv_enforceGameBuild 3095
set resources_useSystemChat true

# Voice
setr voice_useNativeAudio true
setr voice_defaultCycle "GRAVE"
setr voice_defaultVolume 0.3
setr voice_enableRadioAnim 1
setr voice_syncData 1
setr voice_useSendingRangeOnly false

# QBCore
setr qb_locale "en"
setr UseTarget false

# Resources padrão
ensure mapmanager
ensure chat
ensure spawnmanager
ensure sessionmanager
ensure basic-gamemode
ensure hardcap
ensure baseevents

# QBCore & extras
ensure qb-core
ensure [qb]
ensure [standalone]
ensure [voice]
ensure [defaultmaps]

## Permissões (txAdmin já gerencia os admins registrados via painel) ##
add_ace group.admin command allow
add_ace resource.qb-core command allow
add_ace qbcore.god command allow
add_principal qbcore.god group.admin
add_principal qbcore.god qbcore.admin
add_principal qbcore.admin qbcore.mod
EOF
else
  echo "server.cfg já tem o bloco do QBCore, não mexi."
fi

echo
echo "Pronto. Reinicie o servidor pelo txAdmin (Server > Restart Server) pra carregar os resources."
