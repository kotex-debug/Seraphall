# SERAPHALL — guía para Claude Code

Action RPG 2D cenital, cooperativo (2 jugadores), Godot 4.7, GDScript. Responder siempre en español.

## Estructura
- `scripts/autoload/`: `g.gd` (textos ES/EN en `TXT`, ajustes, controles), `prog.gd` (progreso de partida, armas, misiones, guardado), `ach.gd` (logros de perfil, aviso animado, % base 100 + DLC 10/10), `net.gd`, `audio.gd`.
- `scripts/world/world.gd`: mundo entero (mapa 384x96, 4 estratos en franjas de 96 casillas), salas, jefes, pruebas, cooperativo, batallas secretas, final.
- `scripts/world/strata.gd`: datos de los Estratos II–IV y salas añadidas (salas, enemigos, Arcontes, PNJ, cofres, recados, puertas).
- `scripts/world/prologue.gd`: prólogo en sala aparte con jefe tutorial y pausas didácticas.
- `scripts/actors/`: `player.gd`, `enemy.gd` (TYPES; los enemigos nuevos reutilizan la IA de otro con `"ai"`), jefes `boss_*.gd`.
- `scripts/ui/`: `hud.gd`, `menu.gd` (pestañas, Códice, Logros, Mapa, Viajar), `dialog.gd`, `credits.gd`, `title_screen.gd`.
- `tools/*.py`: arte y música procedurales (`gen_strata.py`, `gen_secret.py`, `gen_music_strata.py`, `gen_sfx_ach.py`…).

## Reglas
- Los avisos de GDScript cuentan como errores: tipar variables cuando el tipo venga de un Variant (`var x: int = ...`).
- Tras añadir assets: `godot --headless --path . --import`.
- Comprobar que compila: `godot --headless --editor --quit --path .` (buscar `SCRIPT ERROR`), o `--check-only --script res://ruta.gd` para un archivo.
- Para comprobar recursos en exportado usar `ResourceLoader.exists()`, no `FileAccess.file_exists()` en `res://`.

## Pruebas automáticas
`godot --path . -- --autotest=NOMBRE` (con `SERAPHALL_SHOTS=carpeta` guarda capturas). Útiles:
`flow` (sin pantalla, rápida), `content` (mapa, datos, pruebas nuevas, salas cerradas, pluma por Brasa), `prologue` (tutorial completo), `v9` (Artes, parry, menús), `ach`, `verdugo`, `coloso`, `coopui`, `strata` (recorre los Estratos II–IV, larga), `finale` (Azrahel, final y créditos), `weapons`, `hud`, `title`.
Multijugador: dos procesos a la vez, `--autotest=lobby_host` y, 2 s después, `--autotest=lobby_join`.
Las pruebas usan `user://seraphall_test_slotN.json`: nunca tocan las partidas reales (`seraphall_slot1..3.json`, `Prog.slot`).
También: `slots` (huecos de partida), `economy` (reparto de Ecos por estrato, furia y Cataclismo), `retry` (reintento de jefes).

## Exportar
`godot --headless --path . --export-release "Windows Desktop" build/Seraphall.exe` y comprimir con `tools/LEEME.txt`. En GitHub: subir una etiqueta `v*` lanza `.github/workflows/release.yml`, que compila y publica el zip en Releases. Si cambian las RPC, sube `Net.PROTOCOL`.

## Estado
- Juego base completo: Estratos I–IV, Arcontes Seravel, Orrun, Vulkaris y Azrahel (3 fases), final «La Espiral se rompe» y créditos. v0.9: ver README.
- Claves de v0.9: `world.gd` (salas cerradas `_room_lock_tick`, títulos `_title_tick`, reintentos `_cine_once`), `strata.gd` (`ROOM_TIER`, `GATES`), `prologue.gd` (guion con pausas), `prog.gd` (`WEAPON_ARTS`, `WEAPON_AWAKE`, Resonancia, árbol), `player.gd` (`_cast_art`, parry en dos ventanas).
- Pendiente: pruebas con jugadores para medir las horas y equilibrar los Estratos II–IV, paginar bien el Códice → Personajes, relay online sin abrir puertos (requiere un servidor), rotación real de la cámara en el modo Cámara, DLC I y II.
