#!/bin/bash

set -o errexit
set -o pipefail

# Set optional variables with defaults
BASE_DIR="${BASE_DIR:-/mnt/server}"
BASE_DIR="${BASE_DIR%/}" # Remove trailing slash
STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
STEAMCMD_USER="${STEAMCMD_USER:-anonymous}"
STEAMCMD_PASS="${STEAMCMD_PASS:-}"
STEAMCMD_2FA="${STEAMCMD_2FA:-}"
STEAMCMD_VALIDATE="${STEAMCMD_VALIDATE:-0}"

# Require STEAMCMD_APPID to be set
if [ -z "${STEAMCMD_APPID:-}" ]; then
    echo "Error: STEAMCMD_APPID is required."
    exit 1
fi

# Require STEAMCMD_VALIDATE to be 0 or 1
if [[ "$STEAMCMD_VALIDATE" != [01] ]]; then
    echo "STEAMCMD_VALIDATE must be 0 or 1."; exit 1
fi

# Prepare STEAMCMD_VALIDATE to use as SteamCMD argument
if [[ "$STEAMCMD_VALIDATE" == "1" ]]; then
    STEAMCMD_VALIDATE="validate"
else
    STEAMCMD_VALIDATE=""
fi

echo "Downloading and installing SteamCMD"
mkdir -p "${BASE_DIR}/steamcmd"
curl -sSL "${STEAMCMD_URL}" | tar -xzvf - -C "${BASE_DIR}/steamcmd"

echo "Preparing directories for SteamCMD"
mkdir -p "${BASE_DIR}/steamapps"
cd "${BASE_DIR}/steamcmd" || { echo "Error: Failed to change directory."; exit 1; }
chown -R root:root "${BASE_DIR}"
export HOME="${BASE_DIR}"

echo "Downloading Steam app ${STEAMCMD_APPID}"
"${BASE_DIR}/steamcmd/steamcmd.sh" +force_install_dir "${BASE_DIR}" \
    +login "${STEAMCMD_USER}" "${STEAMCMD_PASS}" "${STEAMCMD_2FA}" \
    +app_update "${STEAMCMD_APPID}" "${STEAMCMD_VALIDATE}" \
    +quit

echo "Copying Steam libraries into place"
mkdir -p "${BASE_DIR}/.steam/sdk32" "${BASE_DIR}/.steam/sdk64"
cp -v "${BASE_DIR}/steamcmd/linux32/steamclient.so" "${BASE_DIR}/.steam/sdk32/steamclient.so"
cp -v "${BASE_DIR}/steamcmd/linux64/steamclient.so" "${BASE_DIR}/.steam/sdk64/steamclient.so"

echo "Done"
