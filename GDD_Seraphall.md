# SERAPHALL — La Caída del Serafín / The Fall of the Seraph
Documento de diseño (GDD) · versión 0.1

## 1. Resumen
- **Género:** Action RPG 2D vista cenital (top-down), estilo Souls-lite, pixel art.
- **Inspiración:** Bloody Hell (ritmo, dash, ángeles vs. infierno), Emberville y Dimraeth (RPG cooperativo, progreso, mundo vivo), Sword Art Online (mundo-prisión por niveles), Elden Ring (jefes semidioses, gracias, lore fragmentado).
- **Plataforma:** PC (Windows .exe). Teclado + ratón y mando.
- **Motor:** Godot 4.7 (gratuito, código abierto).
- **Jugadores:** 1–2 (cooperativo online mediante **código de partida**).
- **Idiomas:** español e inglés.
- **Duración objetivo:** 20–30 h (historia principal ~20 h, completista ~30 h).

## 2. Historia
Hace mil años, el **Dios Arquitecto** encerró a los ángeles caídos en **la Espiral**, un mundo‑prisión que desciende en 100 círculos hacia el Abismo. En la Espiral nadie muere de verdad: se despierta en la última **Brasa** encendida, pero cada muerte arranca una **pluma** y un recuerdo.

Los protagonistas son dos **Desplumados** (en solitario, el segundo aparece como PNJ aliado en la historia). Despiertan en el primer círculo con una orden grabada a fuego: *descender y matar al Rey del Abismo*.

Cada estrato lo gobierna un **Arconte**, guardián de un fragmento del **Nimbo Roto**, la aureola que sella la prisión. Al vencer a un Arconte se recupera su poder (nueva rama/nodo clave del árbol de habilidades) y un recuerdo (escena).

**Giro:** el Rey del Abismo, **Azrahel**, fue el ángel que intentó liberar a todos. La voz que dio la orden es el Arquitecto, el verdadero carcelero.

**Finales:**
1. *Romper el Nimbo:* liberar la Espiral (final verdadero, requiere todos los recuerdos).
2. *Coronarse:* convertirse en el nuevo carcelero.
3. *Final secreto:* subir en vez de bajar y enfrentarse al Arquitecto (jefe secreto).

## 3. Estructura del mundo (10 estratos × 10 círculos)
| # | Estrato | Arconte (jefe principal) | Mecánica del jefe |
|---|---------|--------------------------|-------------------|
| 1 | Vestíbulo de Ceniza | **Seravel, Guardiana de las Puertas** | Espadas orbitantes, 2 fases |
| 2 | Bosque de Plumas Muertas | **Orrun, el Ciervo Hueco** | Cargas y raíces que brotan |
| 3 | Catedral Sumergida | **Madre Lacrima** | Inunda la arena por zonas |
| 4 | Forjas del Juramento | **Vulkaris, el Herrero** | Metal fundido, armas que forja en combate |
| 5 | Biblioteca de los Nombres | **El Archivero** | Invoca páginas/clones, puzle |
| 6 | Desierto de Relojes | **Kronagh** | Ralentiza/rebobina el tiempo |
| 7 | Jardín de Espinas Doradas | **Reina Ysolde** | Espinas que marcan el suelo, baile |
| 8 | Coliseo de los Caídos | **Varek y Vael (gemelos)** | Duo pensado para cooperativo |
| 9 | Ciudad Invertida | **Lucen, el Primer Desplumado** | Duelo espejo (copia tus habilidades) |
| 10 | El Abismo | **Azrahel, Rey del Abismo** | 3 fases + elección final |
| ★ | Cúspide (secreto) | **El Arquitecto** | Jefe secreto |

**Total de jefes previsto: ~35** = 10 Arcontes + 20 jefes menores (2 por estrato) + 4 jefes opcionales/secretos + 1 final secreto.
Cada estrato: un santuario‑Brasa, 3–5 zonas, eventos, mazmorra opcional, 2 jefes menores y su Arconte (~2–2,5 h).

## 4. Combate
- **Ataque ligero:** combo de 3–4 golpes según arma; cancelable con dash.
- **Ataque pesado:** cargable (3 niveles), rompe la guardia (postura).
- **Dash:** invulnerable (i‑frames), consume aguante; doble dash con habilidad.
- **Esquiva perfecta:** dash justo antes del golpe → cámara lenta "Instante" + contraataque.
- **Parry:** ventana corta; si acierta, el enemigo queda aturdido → **Ejecución** (golpe crítico).
- **Hechizos:** gastan **Luz** (maná); se equipan 2 (Q/E). Ejemplos: Lanza de Luz, Nova de Ceniza, Alas de Fuego.
- **Ira Seráfica (definitiva):** barra que se llena golpeando; ataque devastador.
- **Postura:** enemigos y jefes tienen barra de postura; al romperla quedan expuestos.
- **Estados:** Quemadura, Escarcha (ralentiza), Rayo (cadena), Sombra (drena), Sangrado de luz (daño % vida).
- **Telegráficos claros:** destellos y marcas en el suelo antes de cada ataque enemigo.
- **Feedback ("juice"):** hit‑stop, temblor de pantalla, partículas, destellos, números de daño, estelas, luces dinámicas, aplastar/estirar.
- **Cooperativo:** combos entre jugadores (p. ej. uno congela + otro rompe = Fragmentación), revivir al compañero caído.

## 5. Progresión
### 5.1 Personaje
- **Ecos** (moneda/experiencia). Al morir se dejan en el suelo y se pueden recuperar.
- **Nivel** → puntos de atributo: **Vigor** (vida), **Aguante**, **Fuerza**, **Destreza**, **Fe** (hechizos), **Arcano** (estados/suerte).
- **Plumas:** cada Arconte devuelve una pluma → +1 carga de curación (frasco de **Lágrima**) o mejora de su potencia.

### 5.2 Árbol de habilidades (4 ramas, ~80 nodos)
- **Filo** (cuerpo a cuerpo): combos extra, golpes cargados, ejecución, robo de vida.
- **Ala** (movilidad): doble dash, dash ofensivo, Instante más largo, salto‑golpe.
- **Luz** (magia): nuevos hechizos, coste reducido, hechizos que rebotan.
- **Ceniza** (defensa/apoyo): parry más amplio, escudos, auras de grupo, revivir rápido.
- **Nodos clave de Arconte:** cada Arconte desbloquea un nodo único y potente (p. ej. Seravel → "Espadas Orbitantes").
- Puntos de habilidad al subir de nivel y por misiones; reseteo con objeto raro.

### 5.3 Armas
- **Tipos:** espada, lanza, guadañas dobles, martillo, arco, catalizador.
- **Mejora +0 → +10** en la herrería (Brenna) con **Fragmentos de Pluma** y materiales.
- **Armas de jefe:** cada Arconte da un arma única con habilidad especial.
- **Runas:** ranuras para runas (estados, críticos, velocidad...).
- **Rarezas:** común, rara, épica, legendaria, de Arconte.

## 6. Misiones y recompensas
- **Principal:** descender estratos y vencer a los Arcontes.
- **Secundarias:** PNJ del Santuario de la Última Brasa (herrera Brenna, el Cartógrafo Ciego, la Mercader Nyx, el Hermano Oso...), cadenas de varias partes.
- **Recompensas de caza:** volver a enfrentarse a jefes más fuertes.
- **Desafíos:** eventos de oleadas, contrarreloj, reliquias ocultas.
- **Recompensas:** Ecos, armas, runas, materiales, hechizos, puntos de habilidad, cosméticos.
- **Diario de misiones** con seguimiento en pantalla.

## 7. Multijugador
- Hasta **2 jugadores**. El anfitrión crea la partida → recibe un **código** (p. ej. `K7Q2-M9XA`); el amigo lo introduce.
- Fase 1: ENet + UPnP (apertura automática de puerto) + LAN. Fase posterior: relay gratuito (Epic Online Services) para conexiones difíciles.
- El anfitrión controla enemigos y mundo; cada jugador controla su personaje. El progreso de personaje viaja con cada jugador.

## 8. Arte y sonido
- Pixel art 2D, paleta oscura con luces cálidas (brasas) y frías (luz divina).
- Iluminación 2D dinámica, partículas, niebla, shaders.
- Escenas: cinemáticas en motor (cámara, diálogos, retratos).
- Banda sonora: tema principal, tema por estrato, tema por Arconte (fases). Provisional generada por código; sustituible por música definitiva.

## 9. Plan de desarrollo
1. **Fase 1 – Demo jugable:** combate completo, cooperativo con código, Estrato 1 (zona + Seravel), progresión básica (niveles, árbol, mejoras de arma, misiones), ES/EN, .exe.
2. **Fase 2 – Sistemas:** guardado, inventario, diálogos y cinemáticas, santuario con PNJ, mapa.
3. **Fase 3 – Contenido:** estratos 2–10, jefes, armas, hechizos, misiones.
4. **Fase 4 – Pulido:** música y arte definitivos, equilibrio, relay online, finales.
