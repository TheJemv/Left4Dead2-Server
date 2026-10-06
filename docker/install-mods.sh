#!/usr/bin/env bash
# Descarga MetaMod, SourceMod, L4DToolZ, Left4DHooks y los plugins de 8 jugadores
# en una carpeta con la misma estructura que left4dead2/. El entrypoint la copia
# sobre el servidor en cada arranque.
set -euo pipefail

DEST="${1:?uso: install-mods.sh <destino>}"
SM_DIR="$DEST/addons/sourcemod"
HARRY="https://raw.githubusercontent.com/fbef0102/L4D1_2-Plugins/master"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

dl() { curl -fsSL --retry 5 --retry-delay 5 "$@"; }
# Descarga opcional: algunos plugins no traen gamedata o traducciones.
dl_opt() { if dl -o "$TMP/opt" "$1" 2>/dev/null; then mv "$TMP/opt" "$2"; fi; }

mkdir -p "$DEST/addons"

echo ">> MetaMod:Source $MMS_BRANCH"
mms="$(dl "https://mms.alliedmods.net/mmsdrop/$MMS_BRANCH/mmsource-latest-linux")"
dl "https://mms.alliedmods.net/mmsdrop/$MMS_BRANCH/$mms" | tar -xz -C "$DEST"

echo ">> SourceMod $SM_BRANCH"
sm="$(dl "https://sm.alliedmods.net/smdrop/$SM_BRANCH/sourcemod-latest-linux")"
dl "https://sm.alliedmods.net/smdrop/$SM_BRANCH/$sm" | tar -xz -C "$DEST"

# Desbloquea más de 4 jugadores en coop (sv_maxplayers / sv_setmax). Es un plugin VSP,
# se carga con addons/l4dtoolz.vdf.
echo ">> L4DToolZ $L4DTOOLZ_VERSION"
dl -o "$TMP/l4dtoolz.zip" \
  "https://github.com/lakwsh/l4dtoolz/releases/download/$L4DTOOLZ_VERSION/l4dtoolz-$L4DTOOLZ_VERSION-main.zip"
unzip -q -j -o "$TMP/l4dtoolz.zip" l4dtoolz.so l4dtoolz.vdf -d "$DEST/addons"

echo ">> Left4DHooks"
dl "https://github.com/SilvDev/Left4DHooks/archive/refs/heads/main.tar.gz" | tar -xz -C "$TMP"
cp -r "$TMP"/Left4DHooks-main/sourcemod/{plugins,gamedata,data} "$SM_DIR/"

# Plugins de HarryPotter (fbef0102) para 5+ supervivientes en coop.
# Guía: github.com/fbef0102/Game-Private_Plugin -> 8+_Survivors_In_Coop
PLUGINS=(
  l4dmultislots                  # crea un superviviente extra por cada jugador 5+
  l4d_CreateSurvivorBot          # dependencia de l4dmultislots
  l4d_unreservelobby             # quita la reserva de lobby (4) para que entren 8
  l4dafkfix_deadbot              # AFK con bots muertos y 5+ supervivientes
  l4d_both_fixUpgradePack        # munición especial con 5+ supervivientes
  l4d2_vocalizebasedmodel        # voces correctas con personajes L4D1 + L4D2
  l4d2_trigger_flow_fix          # evita que mapas custom se traben con 5+
  l4d2_rescue_vehicle_multi      # rescate final con 5+ supervivientes
  l4d_full_slot_bot_replace_fix  # bots cuando el servidor está lleno
  spawn_infected_nolimit         # dependencia de l4d2_maptankfix
  l4d2_maptankfix                # tanks que no aparecen en mapas custom
)
echo ">> Plugins de 8 jugadores"
for p in "${PLUGINS[@]}"; do
  echo "   - $p"
  dl -o "$SM_DIR/plugins/$p.smx" "$HARRY/$p/plugins/$p.smx"
  dl_opt "$HARRY/$p/gamedata/$p.txt" "$SM_DIR/gamedata/$p.txt"
  dl_opt "$HARRY/$p/translations/$p.phrases.txt" "$SM_DIR/translations/$p.phrases.txt"
done

echo ">> Mods listos en $DEST"
