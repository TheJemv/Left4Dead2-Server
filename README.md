# Left 4 Dead 2 — Servidor dedicado de 8 jugadores (Docker Compose)

Servidor dedicado de L4D2 en cooperativo para **8 jugadores**, con las campañas **Glubtastic 2, 4 y 5** y el mod **8 Player Lobby**, expuesto en el puerto **27015**.

## Qué incluye

- **L4D2 Dedicated Server** (app 222860), instalado y actualizado con steamcmd.
- **MetaMod:Source + SourceMod 1.12**.
- **[L4DToolZ](https://github.com/lakwsh/l4dtoolz)**: desbloquea más de 4 jugadores en coop.
- **[Left4DHooks](https://github.com/SilvDev/Left4DHooks)**.
- **Plugins de 8 jugadores** de [HarryPotter](https://github.com/fbef0102/L4D1_2-Plugins): `l4dmultislots`, `l4d_unreservelobby` y las correcciones para 5+ supervivientes.
- **Mods del Steam Workshop**, que se descargan y actualizan solos al arrancar:

| ID | Mod |
|---|---|
| [2276071285](https://steamcommunity.com/sharedfiles/filedetails/?id=2276071285) | 8 Player Lobby |
| [2066106924](https://steamcommunity.com/sharedfiles/filedetails/?id=2066106924) | Glubtastic 2 (`glubtastic2_1`) |
| [2459037122](https://steamcommunity.com/sharedfiles/filedetails/?id=2459037122) | Glubtastic 4 (`glubtastic4_1`) |
| [3366491323](https://steamcommunity.com/sharedfiles/filedetails/?id=3366491323) | Glubtastic 5 (`glubtastic5_1`) |

## Uso (Ubuntu)

```bash
cp .env.example .env        # opcional: contraseñas de RCON / servidor
docker compose up -d --build
sudo ufw allow 27015        # firewall (TCP y UDP)
docker compose logs -f
```

El primer arranque descarga unos 12 GB (servidor y campañas). Si el servidor está detrás de un router, abre el puerto **27015 TCP/UDP** en el router.

- **Consola del servidor:** `docker attach l4d2-server`. Para salir sin apagarlo: `Ctrl+P`, `Ctrl+Q`.
- **Apagar:** `docker compose down`.

## Configuración

- **`docker-compose.yml`:** nombre del servidor, jugadores, dificultad, mapa inicial y `WORKSHOP_IDS`.
- **`config/`:** se copia encima de `left4dead2/` en cada arranque.
  - `cfg/server.cfg`
  - `cfg/sourcemod/l4dmultislots.cfg`: para jugar siempre con 8 (bots incluidos), pon `min_survivors "8"` y `spawn_survivors_roundstart "1"`.
  - `addons/sourcemod/configs/admins_simple.ini`: agrega tu SteamID para ser admin.

## Cómo entran los jugadores

1. **Todos** deben suscribirse a los 4 ítems del Workshop de la tabla.
2. **Conexión directa:** cada jugador abre la consola y escribe `connect IP_DEL_SERVIDOR:27015`.
3. **Con el lobby de 8:**
   1. Crea el lobby con la mutación *8 Player Lobby*.
   2. En *Change Mode* elige Campaña y luego la Glubtastic.
   3. Como servidor elige "Mejor dedicado disponible".
   4. En la consola escribe `mm_dedicated_force_servers IP_DEL_SERVIDOR:27015`.
4. **Cambiar de campaña:** usa la votación del menú, o `!map glubtastic4_1` si eres admin.

> **Aviso:** el autor de Glubtastic 5 advierte que en servidores dedicados puede dar problemas.
