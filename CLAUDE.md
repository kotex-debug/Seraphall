# SERAPHALL — guía para Claude Code

Action RPG 2D cenital, cooperativo (2 jugadores), Godot 4.7, GDScript. Responder siempre en español.

## Estructura
- `scripts/autoload/`: `g.gd` (textos ES/EN en `TXT`, ajustes, controles), `prog.gd` (progreso de partida, armas, misiones, guardado), `ach.gd` (logros de perfil, aviso animado, % base 100 + DLC 10/10), `net.gd`, `audio.gd`.
- `scripts/world/world.gd`: mundo entero (mapa 384x96, 4 estratos en franjas de 96 casillas), salas, jefes, pruebas, cooperativo, batallas secretas, final.
- `scripts/world/strata.gd`: datos de los Estratos II–IV (salas, enemigos, Arcontes, PNJ, cofres, recados).
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
`flow` (sin pantalla, rápida), `ach`, `verdugo`, `coloso`, `coopui`, `strata` (recorre los Estratos II–IV, larga), `finale` (Azrahel, final y créditos), `weapons`, `hud`, `title`.

## Exportar
`godot --headless --path . --export-release "Windows Desktop" build/Seraphall.exe` y comprimir con `build/LEEME.txt`.

## Estado
- Juego base completo: Estratos I–IV, Arcontes Seravel, Orrun, Vulkaris y Azrahel (3 fases), final «La Espiral se rompe» y créditos.
- Pendiente: probar en Windows real, equilibrar dificultad de los Estratos II–IV, paginar bien el Códice → Personajes, relay online sin abrir puertos, DLC I y II.
