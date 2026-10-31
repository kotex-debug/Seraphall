# SERAPHALL
### La Caída del Serafín · *The Fall of the Seraph*

Action RPG 2D con vista cenital, cooperativo para 2 jugadores, inspirado en *Bloody Hell*, *Emberville*, *Dimraeth*, *Sword Art Online* y *Elden Ring*.

> Hace mil años, el Dios Arquitecto encerró a los ángeles caídos en **la Espiral**, un mundo‑prisión de 100 círculos que desciende hacia el Abismo. Tú eres un **Desplumado**. Desciende, derrota a los **Arcontes** y descubre quién es el verdadero carcelero.

## ⬇️ Descargar y jugar (Windows)
1. Ve a **[Releases](../../releases/latest)** y descarga `Seraphall-Windows.zip`.
2. Descomprime y abre `Seraphall.exe`. No necesita instalación.
3. Si Windows muestra "Windows protegió su PC": pulsa **Más información → Ejecutar de todas formas** (el juego no está firmado digitalmente).

## 🎮 Controles
| Acción | Teclado y ratón | Mando |
|---|---|---|
| Moverse | WASD | Stick izquierdo |
| Apuntar | Ratón | Stick derecho |
| Ataque (combo) | Clic izquierdo | X |
| Ataque pesado (mantén para cargar) | Clic derecho | Y |
| Dash (invulnerable) | Espacio | A |
| Parry | Shift | LB |
| Lanza de Luz / Nova de Ceniza | Q / E | RB / → |
| Ira Seráfica (definitiva) | R | R3 |
| Curar (Lágrima) | C | ↑ |
| Objeto rápido (bomba, incienso…) | X | ↓ |
| Mapa | M | - |
| Modo foto (WASD mover, Q/E zoom, F12 captura) | P | - |
| Interactuar / revivir | F | B |
| Menú (personaje, árbol, armas, misiones) | Tab | Select |

**El gancho:** cada muerte te **arranca una pluma** (se ve en tus alas). Con pocas plumas entras en modo **Desplumado**: más daño y velocidad, menos vida. Encender una Brasa nueva cuesta una pluma. Si mueres dos veces sin recuperar tus Ecos, **tu Sombra** se alza con tu aspecto y tus armas.

**Consejos:** el dash justo antes de un golpe activa el **Instante** (cámara lenta y crítico). Un **parry** perfecto aturde al enemigo. Rompe la **postura** de los enemigos para hacer daño extra. Sube de nivel descansando en las **Brasas**. Mejora tus armas con **Brenna**, la herrera.

## 🤝 Cooperativo (2 jugadores)
- **Anfitrión:** *Crear partida cooperativa* → comparte el **código** (online o de red local).
- **Amigo:** *Unirse con código* → escribe el código.
- El código online usa UPnP para abrir el puerto automáticamente. Si tu router no lo permite, abre el puerto **UDP 24680** o usad el código LAN en la misma red.

## ✨ Contenido de la demo (v0.4)
- **Creador de personaje**: chica o chico, 3 peinados por cuerpo y colores de pelo, piel, ojos, capa, armadura, alas y aureola, con nombre propio. Tu compañero en cooperativo ve tu aspecto.
- **4 modos de dificultad**: Ala Ligera (accesible), Peregrino, Desplumado (recomendado) y Serafín Caído; más el **Segundo Descenso (NG+)**.
- **Plumas y muerte**: plumas visibles en el sprite, modo Desplumado, Brasas que se encienden ofreciendo una pluma, **tu Sombra** como enemigo, primera muerte memorable y una Voz que *miente* (el texto falla y deja ver la verdad).
- **Sala del Nimbo** (estilo mesa redonda): Ozias (grabados de arma: Brasa, Escarcha, Nimbo, Sangre de Luz), Madre Ilse (Lágrimas y coser plumas), Nyx (tienda) y Sor Velaria (**Ascensión** de jefes I-III, **Juramentos** y NG+).
- **3 jefes con cinemática frontal**, cada uno más difícil (rango I-III), ataques especiales, varias fases y salas decoradas: **El Carcelero**, **El Coro Hueco** (tres cantores que se funden en un gigante) y **Seravel** (fase final *Juicio del Nimbo*). Puedes **perdonarlos** rompiendo su postura al borde de la muerte; si mueres mucho contra uno, **te reconoce**.
- **Armas con memoria** (títulos como *Matadora de Carceleros*), **sinergias** ocultas de amuletos, **parry a proyectiles** (devuelves la luz enemiga).
- **Cooperativo**: **Alas Cruzadas** (dash cruzado = tajo en X), revivir **atrapando la pluma** del compañero, conversación exclusiva al sentaros juntos en el mirador.
- **Eventos del mundo**: Lluvia de Ceniza y Eclipse del Nimbo (enemigos más fuertes, mejor botín).
- **Chispa**, una brasa viva que te acompaña, ilumina y presiente secretos.
- Objetos únicos del mundo de Seraphall (Nudo de Brasa, Himno Embotellado, Escama de Querubín, Esquirla de Nimbo...).
- HUD con **minimapa**, contador de **combos** con rangos, indicador de dirección del daño; **mapa** nuevo con iconos y zonas.
- **Accesibilidad**: temblor y destellos ajustables, telegráficos reforzados. **Modo foto**.
- Estrato I: Vestíbulo de Ceniza (8 zonas), 6 armas mejorables (+10), 25 habilidades, español e inglés, música original.

Fuentes: Jersey 10/15, Silkscreen y Pixelify Sans (SIL Open Font License, ver `assets/fonts`).

## 🛠️ Desarrollo
Hecho con **Godot 4.7** (gratis y de código abierto).
- Abre la carpeta con Godot 4.7 → *Importar* → `project.godot`.
- Arte y audio provisionales generados por código: `python3 tools/gen_art.py`, `python3 tools/gen_looks.py` (personaje personalizable) y `python3 tools/gen_audio.py --force`.
- Exportar: *Proyecto → Exportar → Windows Desktop*.

Diseño completo en [`GDD_Seraphall.md`](GDD_Seraphall.md).
