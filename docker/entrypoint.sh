#!/usr/bin/env bash
set -euo pipefail

SERVER_DIR="/home/steam/l4d2"
GAME_DIR="$SERVER_DIR/left4dead2"
STEAMCMD="${STEAMCMDDIR:-/home/steam/steamcmd}/steamcmd.sh"
WORKSHOP_STATE="$SERVER_DIR/.workshop"

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
# 2) MetaMod + SourceMod + L4DToolZ + plugins (de la imagen) y config del usuario
# ---------------------------------------------------------------------------
install_mods() {
  log "Copiando MetaMod, SourceMod, L4DToolZ y plugins de 8 jugadores..."
  cp -r /opt/l4d2/mods/. "$GAME_DIR/"

  if [[ -d /config ]]; then
    log "Aplicando ./config sobre left4dead2/..."
    cp -r /config/. "$GAME_DIR/"
  fi

  # Valores que vienen de docker-compose.yml (server.cfg hace 'exec env.cfg').
  cat > "$GAME_DIR/cfg/env.cfg" <<EOF
// Generado por entrypoint.sh desde docker-compose.yml. No editar: se sobrescribe.
hostname "${SERVER_NAME:-L4D2 8 Jugadores}"
rcon_password "${RCON_PASSWORD:-}"
sv_password "${SERVER_PASSWORD:-}"
sv_maxplayers ${MAX_PLAYERS:-8}
sv_visiblemaxplayers ${MAX_PLAYERS:-8}
z_difficulty "${DIFFICULTY:-Normal}"
EOF
}

# ---------------------------------------------------------------------------
# 3) Workshop: descarga los .vpk vía la API pública de Steam (sin login)
# ---------------------------------------------------------------------------
download_workshop() {
  local raw="${WORKSHOP_IDS:-}" ids
  read -r -a ids <<<"${raw//,/ }"
  mkdir -p "$WORKSHOP_STATE" "$GAME_DIR/addons"

  # Borra los .vpk de items que ya no están en WORKSHOP_IDS.
  local f id
  for f in "$GAME_DIR"/addons/workshop_*.vpk; do
    [[ -e "$f" ]] || continue
    id="$(basename "$f" .vpk)"; id="${id#workshop_}"
    if [[ " ${ids[*]} " != *" $id "* ]]; then
      echo "   - quitando $id"
      rm -f "$f" "$WORKSHOP_STATE/$id"
    fi
  done

  (( ${#ids[@]} )) || return 0
  log "Steam Workshop: ${ids[*]}"

  local args=(-d "itemcount=${#ids[@]}") i=0 json
  for id in "${ids[@]}"; do args+=(-d "publishedfileids[$i]=$id"); i=$((i + 1)); done
  json="$(curl -fsSL --retry 5 --retry-delay 5 \
    https://api.steampowered.com/ISteamRemoteStorage/GetPublishedFileDetails/v1/ "${args[@]}")"

  # "-" como relleno: con IFS=tab, read colapsa campos vacíos.
  local result updated size url title vpk
  while IFS=$'\t' read -r id result updated size url title; do
    vpk="$GAME_DIR/addons/workshop_$id.vpk"
    if [[ "$result" != "1" || "$url" == "-" ]]; then
      echo "   ! $id: no disponible en el Workshop (result=$result), se omite"
      continue
    fi
    if [[ -f "$vpk" && "$(cat "$WORKSHOP_STATE/$id" 2>/dev/null)" == "$updated" ]]; then
      echo "   = $title ($id) al día"
      continue
    fi
    echo "   v $title ($id) — $((size / 1024 / 1024)) MB, descargando..."
    curl -fSL --retry 5 --retry-delay 5 -s -o "$vpk.part" "$url"
    mv "$vpk.part" "$vpk"
    echo "$updated" >"$WORKSHOP_STATE/$id"
  done < <(jq -r '.response.publishedfiledetails[]
      | [ .publishedfileid, (.result | tostring), (.time_updated // 0 | tostring),
          (.file_size // "0" | tostring), (.file_url // "-" | if . == "" then "-" else . end),
          (.title // "-") ] | @tsv' <<<"$json")
}

# ---------------------------------------------------------------------------
# 4) Arrancar srcds
# ---------------------------------------------------------------------------
install_server
link_steamclient
install_mods
download_workshop

log "Iniciando servidor en el puerto 27015 (mapa ${START_MAP:-c1m1_hotel}, modo ${GAME_MODE:-coop})"
cd "$SERVER_DIR"
exec ./srcds_run -game left4dead2 -console -norestart -port 27015 \
  +sv_setmax 31 \
  +mp_gamemode "${GAME_MODE:-coop}" \
  +map "${START_MAP:-c1m1_hotel}"
