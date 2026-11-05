# SERAPHALL
### La Caída del Serafín · *The Fall of the Seraph*

**Seraphall** es un videojuego **action RPG 2D gratuito** para Windows, con vista cenital y cooperativo para 2 jugadores, inspirado en *Bloody Hell*, *Emberville*, *Dimraeth*, *Sword Art Online* y *Elden Ring*. Web del juego: **[kotex-debug.github.io/Seraphall](https://kotex-debug.github.io/Seraphall/)**.

*Seraphall is a free top-down 2D action RPG for Windows with 2-player co-op.*

> Hace mil años, el Dios Arquitecto encerró a los ángeles caídos en **la Espiral**, un mundo‑prisión de 100 círculos que desciende hacia el Abismo. Tú eres un **Desplumado**. Desciende, derrota a los **Arcontes** y descubre quién es el verdadero carcelero.

## ⬇️ Descargar y jugar (Windows)
1. Ve a **[Releases](../../releases/latest)** y descarga `Seraphall-Windows.zip`.
2. Descomprime y abre `Seraphall.exe`. No necesita instalación.
3. Si Windows muestra "Windows protegió su PC": pulsa **Más información → Ejecutar de todas formas** (el juego no está firmado digitalmente).

## 🎮 Controles
| Acción | Teclado y ratón | Mando |
|---|---|---|
| Moverse | WASD | Stick izquierdo |
| Apuntar | Ratón (o por movimiento: ver *Opciones → Combate*) | Stick derecho |
| Ataque básico (combo de 4 golpes distintos) | Clic izquierdo | X |
| Ataque cargado (mantén) | Espacio | Y |
| Dash (invulnerable) | Shift | A |
| Parry (desvía proyectiles) | Clic derecho | LB |
| Pluma Dorada / Nova de Ceniza *(se desbloquean)* | Q / E | RB / → |
| Ira Seráfica *(se desbloquea)* | R | R3 |
| Arte de arma *(se desbloquea)* | V | L3 |
| Curar (Lágrima) | C | ↑ |
| Objeto rápido (bomba, incienso…) | X | ↓ |
| Mapa | M | - |
| Modo foto (WASD mover, Q/E zoom, F12 captura) | P | - |
| Interactuar / revivir | F | B |
| Menú (personaje, árbol, armas, misiones, **controles**) | Tab | Select |
| Pantalla completa | F11 o Alt+Intro | - |

Todos los controles se pueden **reasignar** en *Menú → Controles*; las teclas de cada ataque aparecen allí cuando lo desbloqueas. Al empezar solo tienes el ataque básico: la **Pluma Dorada** se consigue al encender la Brasa del Santuario, el **Arte de arma** al hablar con Brenna, la **Nova** en el árbol de habilidades y la **Ira Seráfica** al vencer al Carcelero.

**Dos formas de pelear** (*Opciones → Combate*): **Puntero** (apuntas con el ratón) y **Movimiento** (atacas hacia donde caminas y te encaras solo al enemigo cercano).

**El gancho:** cada muerte te **arranca una pluma** (se ve en tus alas). Con pocas plumas entras en modo **Desplumado**: más daño y velocidad, menos vida. Si mueres dos veces sin recuperar tus Ecos, **tu Sombra** se alza con tu aspecto y tus armas.

## 🪶 Las plumas: cómo se pierden y cómo se recuperan
Tienes **10 plumas** en las alas y se ven en tu personaje (y en el HUD, bajo las Lágrimas).

**Se pierden** de dos formas: **al morir** se arranca una pluma, y **encender una Brasa** cuesta otra (la echas al fuego). Sin plumas, la Brasa se enciende gratis.

**Se recuperan** así:
| Forma | Cómo |
|---|---|
| **Recoger tus Ecos caídos** | La pluma arrancada cae al suelo junto a tus Ecos, donde moriste. Vuelve a ese sitio y recógelos: recuperas la pluma. |
| **Vencer a tu Sombra** | Si mueres otra vez antes de recoger tus Ecos, esos Ecos y sus plumas pasan a tu **Sombra**. Derrótala y recuperas **todas** las plumas que guardaba. |
| **Madre Ilse** (Sala del Nimbo) | Te **cose una pluma** a cambio de una **Lágrima de Serafín** (las sueltan jefes y cofres). |
| **Derrotar a un Arconte** | La primera vez que vences a un Arconte, te **devuelve 2 plumas**. |
| **Dificultad Ala Ligera** | Cada vez que **descansas en una Brasa** te crece una pluma. |
| **Pluma Áurea** *(recompensa secreta)* | Tras superar el Panteón de los Arcontes, la **primera caída después de cada descanso no arranca ninguna pluma**. |

> Los **Fragmentos de Pluma** son otra cosa: un material para que Brenna mejore tus armas.
> Quedarte con **3 plumas o menos** activa el modo **Desplumado** (más daño y velocidad, menos vida). Conservar **7 o más** inclina la *balanza del destino* hacia las **Alas**; quedarte con 3 o menos, hacia el **Trono**.

**Consejos:** el dash (Shift) justo antes de un golpe activa el **Instante** (cámara lenta y crítico). El **parry** (clic derecho) tiene dos ventanas: el **desvío** anula el daño y el **parry perfecto** aturde, devuelve los proyectiles con el doble de fuerza y deja lista una **Réplica** (tu siguiente golpe se lanza contra el enemigo, crítico y mucho más fuerte). Los parries perfectos seguidos se encadenan. Rompe la **postura** de los enemigos para hacer daño extra. Sube de nivel descansando en las **Brasas**. Mejora tus armas con **Brenna**, la herrera.

## 🤝 Cooperativo (2 jugadores)
- **Anfitrión:** *Crear partida cooperativa* → comparte el **código** y pulsa **Empezar** cuando quieras. Tu amigo espera en la sala hasta entonces (o entra después).
- **Amigo:** *Unirse con código* → en la **misma red** tu partida aparece sola en la lista: basta con pulsarla. Si no, escribe el código o la IP.
- **Por Internet** el código online usa UPnP para abrir el puerto automáticamente. Si tu router no lo permite, o tu proveedor no te da IP pública (CGNAT, el juego te avisa), abre el puerto **UDP 24680** o usad una red virtual gratuita (**Tailscale**, **Radmin VPN**, **ZeroTier**) y conectad por IP directa.
- Si Windows pregunta, **permite Seraphall en el Firewall**, sobre todo el anfitrión.
- Los dos tenéis que usar **la misma versión** del juego (si no, el juego os lo dice).
- **Ficha del compañero** en pantalla: su vida, sus plumas, la distancia y hacia dónde está. Si sale de la pantalla, una **flecha en el borde** te lleva hasta él.
- **Marcas (tecla G):** apunta con el ratón y marca un sitio, un enemigo («¡ENEMIGO!») o un objeto («¡MIRA ESTO!»). Tu compañero lo ve con una baliza de luz y una flecha si está lejos.
- **Revivir:** si cae, suelta una pluma que revolotea: **atrápala** para revivirle (vuelve con la mitad de la vida). Al revivir, los dos ganáis **Alas Unidas** (+20% de daño durante 10 s).
- **Alas Cruzadas:** si los dos hacéis un dash cruzado a la vez, dais un tajo en X devastador.
- **Viajar al compañero:** al descansar en una Brasa, *Personaje → Viajar al compañero* te lleva junto a él.
- **Báculo del Alba:** sus círculos de luz curan a los dos.

## 🏆 Logros (estilo consola)
- Son de **tu perfil**: valen para todas tus partidas. Están en *Menú → Logros*.
- Al conseguir uno salta un **aviso animado** (medallón que gira, rayos, plumas y fanfarria). Los épicos tienen versión especial.
- El **juego base reparte el 100 %**. Cada logro da **XP** y vale un % según su dificultad (bronce, plata, oro o épico).
- Los **dos DLC añadirán un 10 % cada uno**: con ellos se podrá llegar al **120 %** (sus logros ya se ven, bloqueados).
- Hay logros de **historia** (se consiguen jugando, con barra de progreso), de **exploración**, **combate**, **destino**, **cooperativo**, **desafíos de verdad** (sin recibir golpes, sin beber Lágrimas, con las 10 plumas, sin morir…) y **ocultos**.

## ⚔️ Batallas secretas
Tres combates épicos escondidos, con recompensas que no se consiguen de otra forma:
- **El Verdugo** *(el que fuiste)*: presencia los **cuatro ecos del pasado** y se abrirá algo bajo la Capilla Olvidada. Duelo espejo contra tu propio repertorio. Recompensa: la **Hoja del Verdugo** (arma).
- **El Coloso del Abismo**: hay un muro agrietado al norte del Mirador… y un cuerno que solo responde a quien ha cruzado las Puertas. Solo se le hiere en las runas de sus manos y en su núcleo. Recompensa: **Ala de Tormenta** (tu dash invoca rayos) y **Corazón del Coloso** (+15 % de vida y +1 Lágrima).
- **Panteón de los Arcontes**: Sor Velaria lo ofrece cuando has vencido a los tres Arcontes y superado alguna Ascensión. Los tres seguidos en Ascensión II. Recompensa: la **Pluma Áurea**.

## 🧪 ALFA FINAL (v0.9.1)
- **Prólogo nuevo** en una sala aparte, la **Cuna de Ceniza**: un jefe sencillo te enseña las mecánicas parando el juego cuando tienes que reaccionar. Termina llegando al Santuario.
- **Salas que se cierran**: al entrar en una sala con enemigos no sales hasta acabar con todos. Despiertan por tandas, los enemigos no abandonan su sala y lo que limpias sigue limpio hasta que descansas.
- **Dificultad progresiva**: las primeras salas de cada zona perdonan mucho más (menos en Serafín Caído).
- **Parry renovado** (desvío, parry perfecto, Réplica y cadenas) y **Pluma Dorada** en la Q: atraviesa, estalla en esquirlas y vuelve a tu mano.
- **15 armas con arte nuevo** (guadaña, mangual, maza del Yunque, astas de Orrun, cetro del Rey...), cada una con su **Arte** [V] y su **Despertar**. Mejoras con hitos en +3, +5 y +10 y menú de armas rehecho.
- **Árbol de habilidades ampliado**: 66 nodos en 6 ramas (nueva rama **Pluma** y un poder por cada jefe), elecciones excluyentes, **Estigmas** finales, maestría por rama y opción de olvidar en las Brasas.
- **Tres huecos de partida**: *Nueva partida* abre la pantalla de partidas, donde eliges hueco, continúas o borras (con confirmación). *Continuar* abre la última que jugaste. Tu partida anterior pasa sola al hueco 1.
- **Economía reequilibrada**: subir de nivel, mejorar armas y comprar cuesta más; repetir una sala ya limpiada rinde poco, y los cofres y misiones pagan una cantidad fija. No podrás comprarlo todo en una sola partida: toca elegir.
- **Moneda mejorada**: los Ecos vuelan hacia ti y la **Resonancia** (racha de bajas sin recibir golpes) multiplica lo que ganas.
- **Jefes de verdad en cualquier dificultad**: hasta en Ala Ligera tienen todas sus fases, y al borde de la muerte entran en **Furia Final** y desatan su **Cataclismo**. Menú de elección de dificultad rehecho.
- **Anuncios épicos** al conseguir una habilidad o un arma, **jefes sin repetir la presentación** al reintentar (y siempre con su barra), **títulos de sala** que no se pisan y **diario de misiones** con filtros, páginas y seguimiento.
- **Más contenido en cada Arconte**: 14 salas nuevas, 7 pruebas con su **Heraldo**, las puertas de los Arcontes se ganan, 4 PNJ con su encargo, 8 cacerías, 3 recuerdos, nuevas Brasas, cofres e inscripciones.
- **Multijugador arreglado**: el amigo ya no se queda colgado si conecta antes de que empieces. Sala de espera, comprobación de versión, tiempos límite con mensajes claros y búsqueda de partidas en la red local.

## 🧪 Versión ALFA 0.7
- **Pantalla completa** (F11, Alt+Intro, o desde el inicio y Opciones; se recuerda) y **nuevo icono** de la aplicación.
- **Salas antes de cada jefe**: *Las Celdas de Espera* (tres oleadas que salen de las celdas, el preso Tobías y un atajo), *El Atrio de las Voces* (puzle de campanas que hay que tañer «al revés») y *La Escalinata y la Antesala del Juicio* (Brasa nueva y el mini-jefe **El Custodio del Umbral**).
- **Barras de jefe épicas** con marco propio (cadenas, tubos de órgano, plumas de oro), nombre que se escribe letra a letra, daño acumulado, muescas de fase que se rompen y estallido final.
- **Más 3D**: pilares y estatuas que se inclinan en perspectiva, abismo con capas de paralaje, faldones de roca con profundidad, pozos con cadenas y de luz, escombros con altura.
- **Jefes en 3D**: jaulas y espadas que caen desde la cámara, aureola-anillo 3D de Seravel (que se acerca al elevarse), bola del Carcelero orbitando su cuerpo y carrusel de cantores del Coro.
- **Retrato animado** en la interfaz (parpadea, se queja, se apura con poca vida, sonríe al curarse) y **mapa** con grosor, pozos, pruebas y cierres.

## 🧪 Versión ALFA 0.6
- **Corto de introducción** que cuenta la historia antes de empezar, y **Prólogo opcional** que enseña la interfaz, el combate, el dash, el parry y la curación.
- **Giros de guion** a medida que avanzas: lo que de verdad guardaban las celdas, por qué el Coro canta al revés y quién arrancó la primera pluma de Seravel.
- **Salas de jefe selladas**: al entrar se cierran con rejas, tubos de órgano o un muro de luz hasta que acaba el combate.
- **Pozos con profundidad** al estilo *Bloody Hell*: paredes en perspectiva que se mueven con la cámara y un núcleo de brasa o de vacío en el fondo.
- **Combos variados** por arma (barrido, revés, tajo vertical y remate propio), **controles configurables** y habilidades que se desbloquean jugando.
- **Arte rehecho**: PNJ, enemigos y objetos a tamaño proporcional y con detalle propio; nuevas monedas, plumas y **viales de vida, Luz y aliento**; suelos con escombros, huesos, ceniza y runas.
- Animaciones de curación y recarga en el HUD, sonidos de interfaz más suaves y textos en un castellano más natural.

## 🧪 Versión ALFA 0.5
- **Juego base de ~10 h** con final abierto, más **2 DLC de ~5 h** (*Los Cielos Rotos* y *El Abismo Sin Nombre*), cada uno con su final, que llevan a **2 finales definitivos** (*Alas Abiertas* o *El Trono Vacío*). La alfa incluye el Estrato I completo y la **balanza del destino**, que ya registra tus decisiones.
- **Banda sonora original con leitmotivs**: el tema de la Pluma, el de la Voz, el de Seravel, el lamento del Coro y la Cadena reaparecen transformados en cada pista. Hay temas propios para cada jefe y cambian en la fase final, ambientes espeluznantes, latido con poca vida y **voces de diálogo distintas para cada personaje**.
- **HUD con iconos animados**: corazones, llamas de aguante y cristales de Luz.
- **Protagonista más detallado** (32×32): cara, bufanda, hombrera, emblema, botas, capa con pliegues y alas con plumas sombreadas.

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
- Arte y audio provisionales generados por código: `python3 tools/gen_art.py`, `python3 tools/gen_looks.py` (personaje personalizable) y `python3 tools/gen_music.py` (banda sonora y voces), `python3 tools/gen_hud.py` (iconos del HUD). Armas: `godot --headless --path . --script res://tools/gen_weapons.gd`.
- Exportar: *Proyecto → Exportar → Windows Desktop*. Al subir una etiqueta `v*` a GitHub, una acción compila el juego y publica `Seraphall-Windows.zip` en Releases.

Diseño completo en [`GDD_Seraphall.md`](GDD_Seraphall.md).
