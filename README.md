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
| Interactuar / revivir | F | B |
| Menú (personaje, árbol, armas, misiones) | Tab | Select |

**Consejos:** el dash justo antes de un golpe activa el **Instante** (cámara lenta y crítico). Un **parry** perfecto aturde al enemigo. Rompe la **postura** de los enemigos para hacer daño extra. Sube de nivel descansando en las **Brasas**. Mejora tus armas con **Brenna**, la herrera.

## 🤝 Cooperativo (2 jugadores)
- **Anfitrión:** *Crear partida cooperativa* → comparte el **código** (online o de red local).
- **Amigo:** *Unirse con código* → escribe el código.
- El código online usa UPnP para abrir el puerto automáticamente. Si tu router no lo permite, abre el puerto **UDP 24680** o usad el código LAN en la misma red.

## ✨ Contenido de la demo (v0.1)
- Estrato I: Vestíbulo de Ceniza (5 zonas)
- Jefe principal **Seravel, Guardiana de las Puertas** (2 fases) y jefe menor **El Carcelero**
- 5 armas mejorables (+10), árbol de habilidades con 25 nodos en 5 ramas, 6 atributos
- 5 misiones (principal, secundarias y caza) con recompensas
- Español e inglés, música y efectos originales

## 🛠️ Desarrollo
Hecho con **Godot 4.7** (gratis y de código abierto).
- Abre la carpeta con Godot 4.7 → *Importar* → `project.godot`.
- Arte y audio provisionales generados por código: `python3 tools/gen_art.py` y `python3 tools/gen_audio.py --force`.
- Exportar: *Proyecto → Exportar → Windows Desktop*.

Diseño completo en [`GDD_Seraphall.md`](GDD_Seraphall.md).
