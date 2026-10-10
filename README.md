# Left 4 Dead 2 — Servidor dedicado de versus vanilla (Docker Compose)

Servidor dedicado de L4D2 en **versus 4 vs 4**, sin mods: el juego normal con las campañas oficiales. Usa el puerto **27015**.

## Qué incluye

- **L4D2 Dedicated Server** (app 222860), instalado y actualizado con steamcmd.
- **MetaMod:Source + SourceMod 1.12**, solo para los permisos de admin. No cambian la jugabilidad.

## Uso (Ubuntu)

```bash
cp .env.example .env        # opcional: contraseñas de RCON / servidor
docker compose up -d --build
sudo ufw allow 27015        # firewall (TCP y UDP)
docker compose logs -f
```

El primer arranque descarga el servidor (unos 10 GB). Si el servidor está detrás de un router, abre el puerto **27015 TCP/UDP** en el router.

- **Consola del servidor:** `docker attach l4d2-server`. Para salir sin apagarlo: `Ctrl+P`, `Ctrl+Q`.
- **Apagar:** `docker compose down`.

## Configuración

- **`docker-compose.yml`:** nombre del servidor, modo de juego (`versus`), mapa inicial y VAC (`VAC: "0"` = desactivado).
- **`config/`:** se copia encima de `left4dead2/` en cada arranque.
  - `cfg/server.cfg`
  - `addons/sourcemod/configs/admins_simple.ini`: admins del servidor.

## Admins

| Jugador | SteamID | Permisos |
|---|---|---|
| [TheBBC](https://steamcommunity.com/profiles/76561199822275148) | `STEAM_1:0:931004710` | Acceso total (`99:z`) |

En el chat del juego: `!admin` (menú), `!map c2m1_highway`, `!kick`, `!ban`...

Para agregar otro admin, añade su SteamID a `admins_simple.ini` y reinicia con `docker compose restart`.

## Cómo entran los jugadores

1. **Conexión directa:** cada jugador abre la consola y escribe `connect IP_DEL_SERVIDOR:27015`.
   - Para cambiar de equipo, en la consola: `jointeam 2` (supervivientes) o `jointeam 3` (infectados).
2. **Con lobby** (los equipos se arman en el lobby):
   1. Crea un lobby de Versus e invita a los demás.
   2. Como servidor elige "Mejor dedicado disponible".
   3. En la consola escribe `mm_dedicated_force_servers IP_DEL_SERVIDOR:27015` y empieza la partida.
3. **Cambiar de campaña:** usa la votación del menú, o `!map c2m1_highway` si eres admin.
