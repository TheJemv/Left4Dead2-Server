#!/usr/bin/env bash
# Descarga MetaMod:Source y SourceMod en una carpeta con la misma estructura que
# left4dead2/. Solo se usan para los permisos de admin: no cambian el juego.
# El entrypoint la copia sobre el servidor en cada arranque.
set -euo pipefail

DEST="${1:?uso: install-sourcemod.sh <destino>}"

dl() { curl -fsSL --retry 5 --retry-delay 5 "$@"; }

mkdir -p "$DEST"

echo ">> MetaMod:Source $MMS_BRANCH"
mms="$(dl "https://mms.alliedmods.net/mmsdrop/$MMS_BRANCH/mmsource-latest-linux")"
dl "https://mms.alliedmods.net/mmsdrop/$MMS_BRANCH/$mms" | tar -xz -C "$DEST"

echo ">> SourceMod $SM_BRANCH"
sm="$(dl "https://sm.alliedmods.net/smdrop/$SM_BRANCH/sourcemod-latest-linux")"
dl "https://sm.alliedmods.net/smdrop/$SM_BRANCH/$sm" | tar -xz -C "$DEST"

echo ">> MetaMod y SourceMod listos en $DEST"
