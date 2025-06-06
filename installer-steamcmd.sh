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

# Set up color functions
echo_info(){ echo -e "\033[0;32m$*\033[0m"; }
echo_error(){ echo -e "\033[0;31m$*\033[0m" >&2; }
echo_warning(){ echo -e "\033[0;33m$*\033[0m"; }

# Require STEAMCMD_APPID to be set
if [ -z "${STEAMCMD_APPID:-}" ]; then
    echo_error "Error: STEAMCMD_APPID is required"
    exit 1
fi

# Require STEAMCMD_VALIDATE to be 0 or 1
if [[ "$STEAMCMD_VALIDATE" != [01] ]]; then
    echo_error "STEAMCMD_VALIDATE must be 0 or 1"
    exit 1
fi

# Prepare STEAMCMD_VALIDATE to use as SteamCMD argument
if [[ "$STEAMCMD_VALIDATE" == "1" ]]; then
    STEAMCMD_VALIDATE="validate"
else
    STEAMCMD_VALIDATE=""
fi

echo_info "Downloading and extracting SteamCMD"
mkdir -p "${BASE_DIR}/steamcmd"
curl -sSL "${STEAMCMD_URL}" | tar -xzvf - -C "${BASE_DIR}/steamcmd"

echo_info "Preparing directories for SteamCMD"
mkdir -p "${BASE_DIR}/steamapps"
cd "${BASE_DIR}/steamcmd"
chown -R root:root "/mnt"
export HOME="${BASE_DIR}"

STEAMCMD_ARGS=(
    +force_install_dir "${BASE_DIR}"
    +login "${STEAMCMD_USER}" "${STEAMCMD_PASS}" "${STEAMCMD_2FA}"
    +app_update "${STEAMCMD_APPID}" "${STEAMCMD_VALIDATE}"
    +quit
)

echo_info "Starting SteamCMD and downloading Steam app ${STEAMCMD_APPID}"
echo_info "${BASE_DIR}/steamcmd/steamcmd.sh ${STEAMCMD_ARGS[*]}"
if {
    "${BASE_DIR}/steamcmd/steamcmd.sh" "${STEAMCMD_ARGS[@]}"
}; then
    echo_info "SteamCMD successfully downloaded, updated or validated Steam app ${STEAMCMD_APPID}"
else
    echo_warning "SteamCMD exited with code $?"
fi

echo_info "Copying Steam libraries into place"
mkdir -p "${BASE_DIR}/.steam/sdk32" "${BASE_DIR}/.steam/sdk64"
cp "${BASE_DIR}/steamcmd/linux32/steamclient.so" "${BASE_DIR}/.steam/sdk32/steamclient.so"
cp "${BASE_DIR}/steamcmd/linux64/steamclient.so" "${BASE_DIR}/.steam/sdk64/steamclient.so"

echo_info "Successfully installed SteamCMD and Steam app ${STEAMCMD_APPID}"
