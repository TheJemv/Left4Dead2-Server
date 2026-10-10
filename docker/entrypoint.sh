#!/usr/bin/env bash
set -euo pipefail

SERVER_DIR="/home/steam/l4d2"
GAME_DIR="$SERVER_DIR/left4dead2"
STEAMCMD="${STEAMCMDDIR:-/home/steam/steamcmd}/steamcmd.sh"

log() { printf '\n>> %s\n' "$*"; }
die() { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# 1) Instalar / actualizar el servidor dedicado (app 222860)
# ---------------------------------------------------------------------------
steamcmd_update() { # $1 = plataforma (windows|linux), resto = args de app_update
  local platform="$1"; shift
  "$STEAMCMD" +@sSteamCmdForcePlatformType "$platform" +force_install_dir "$SERVER_DIR" \
    +login anonymous +app_update 222860 "$@" +quit 2>&1 | tee /tmp/steamcmd.log || true
  grep -q "Success! App '222860'" /tmp/steamcmd.log
}

install_server() {
  if [[ -f "$SERVER_DIR/srcds_run" && "${UPDATE_ON_START:-1}" != "1" ]]; then
    log "UPDATE_ON_START=0: no se buscan actualizaciones del juego"
    return
  fi
  log "Instalando/actualizando L4D2 Dedicated Server (app 222860)..."
  if [[ -f "$SERVER_DIR/srcds_run" ]] && steamcmd_update linux; then
    return
  fi
  # Steam rechaza la instalación anónima directa en Linux ("Invalid platform").
  # Solución conocida: bajar como Windows y luego validar como Linux para los binarios.
  log "Aplicando workaround de plataforma (windows -> linux)..."
  steamcmd_update windows || true
  steamcmd_update linux validate || true
  [[ -f "$SERVER_DIR/srcds_run" ]] || die "steamcmd no pudo instalar el servidor (ver log arriba)"
  chmod +x "$SERVER_DIR/srcds_run" "$SERVER_DIR/srcds_linux" || true
}

# El servidor busca steamclient.so aquí para registrarse en Steam.
link_steamclient() {
  mkdir -p "$HOME/.steam/sdk32"
  [[ -e "$HOME/.steam/sdk32/steamclient.so" ]] ||
    ln -sf "${STEAMCMDDIR:-/home/steam/steamcmd}/linux32/steamclient.so" "$HOME/.steam/sdk32/steamclient.so"
}

# ---------------------------------------------------------------------------
# 2) MetaMod + SourceMod (solo admins, de la imagen) y config del usuario
# ---------------------------------------------------------------------------
install_sourcemod() {
  # Juego vanilla: plugins/ se rehace en cada arranque (los de SourceMod + los de
  # config/). También quita lo que dejó en el volumen la versión de 8 jugadores
  # (L4DToolZ, sus plugins y los mapas del Workshop).
  rm -rf "$GAME_DIR/addons/sourcemod/plugins" "$SERVER_DIR/.workshop"
  rm -f "$GAME_DIR"/addons/l4dtoolz.* "$GAME_DIR"/addons/workshop_*.vpk \
    "$GAME_DIR/cfg/sourcemod/l4dmultislots.cfg"

  log "Copiando MetaMod y SourceMod (solo para admins)..."
  cp -r /opt/l4d2/sourcemod/. "$GAME_DIR/"

  if [[ -d /config ]]; then
    log "Aplicando ./config sobre left4dead2/..."
    cp -r /config/. "$GAME_DIR/"
  fi

  # Valores que vienen de docker-compose.yml (server.cfg hace 'exec env.cfg').
  cat > "$GAME_DIR/cfg/env.cfg" <<EOF
// Generado por entrypoint.sh desde docker-compose.yml. No editar: se sobrescribe.
hostname "${SERVER_NAME:-L4D2 Versus}"
rcon_password "${RCON_PASSWORD:-}"
sv_password "${SERVER_PASSWORD:-}"
EOF
}

# ---------------------------------------------------------------------------
# 3) Arrancar srcds
# ---------------------------------------------------------------------------
install_server
link_steamclient
install_sourcemod

log "Iniciando servidor en el puerto 27015 (mapa ${START_MAP:-c1m1_hotel}, modo ${GAME_MODE:-versus})"
cd "$SERVER_DIR"
extra_args=()
if [[ "${VAC:-1}" == "0" ]]; then
  log "VAC desactivado (-insecure)"
  extra_args+=(-insecure)
fi
exec ./srcds_run -game left4dead2 -console -norestart -port 27015 "${extra_args[@]}" \
  +mp_gamemode "${GAME_MODE:-versus}" \
  +map "${START_MAP:-c1m1_hotel}"
