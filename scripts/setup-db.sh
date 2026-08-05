#!/usr/bin/env bash
# Setup idempotente do MySQL/MariaDB nativo para o QBCore.
# Precisa de sudo interativo — rode este script diretamente no seu terminal,
# não via automação sem TTY.
# Fonte: https://qbcore.net/docs/installation/linux (Step 3)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env"
DB_NAME="qbcore"
DB_USER="qbcore"

if [[ -f "${ENV_FILE}" ]] && grep -q '^QBCORE_DB_PASSWORD=' "${ENV_FILE}"; then
  DB_PASSWORD="$(grep '^QBCORE_DB_PASSWORD=' "${ENV_FILE}" | cut -d= -f2-)"
  echo "Reutilizando senha existente em .env"
else
  DB_PASSWORD="$(openssl rand -base64 24 | tr -d '/+=')"
  echo "QBCORE_DB_PASSWORD=${DB_PASSWORD}" >> "${ENV_FILE}"
  echo "Senha gerada e salva em .env (gitignored)."
fi

if ! dpkg -l mariadb-server &>/dev/null; then
  echo "Instalando mariadb-server..."
  sudo apt update
  sudo apt install -y mariadb-server mariadb-client
else
  echo "mariadb-server já instalado."
fi

echo "Garantindo que o MariaDB está rodando..."
sudo systemctl enable --now mariadb

echo "Criando database e usuário (idempotente)..."
sudo mysql <<SQL
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
SQL

echo
echo "Banco pronto: mysql://${DB_USER}:<senha em .env>@localhost/${DB_NAME}?charset=utf8mb4"
echo "Copie o valor para mysql_connection_string em server/server.cfg (ver server.cfg.example)."
echo
echo "Se ainda não rodou, execute manualmente 'sudo mysql_secure_installation' uma vez"
echo "(interativo — define senha de root, remove usuários anônimos/test db)."
