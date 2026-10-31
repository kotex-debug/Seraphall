# SERAPHALL — Documento de diseño (resumen v0.5)

**Frase gancho:** *La muerte te arranca plumas.*

## Estructura (~20 h)
| Parte | Duración | Contenido | Final |
|---|---|---|---|
| **Juego base** | ~10 h | Estratos I–IV: Vestíbulo de Ceniza (Seravel), Bosque de Plumas Muertas (Orrun), Fundición de Halos (Vulkaris), El Trono Vacío (Azrahel) | **Abierto**: la Voz era el Arquitecto y la Espiral se rompe hacia arriba y hacia abajo. *Continuará.* |
| **DLC I: Los Cielos Rotos** | ~5 h | Subir a los cielos del Arquitecto: Varek y Vael, Lucen el Primer Desplumado, La Mano del Arquitecto | "Las Puertas del Cielo" |
| **DLC II: El Abismo Sin Nombre** | ~5 h | Bajar bajo la Espiral: La Madre de las Sombras, El Rey Sin Nombre | "El Fondo" |

## Los 2 finales definitivos
Dependen de la **balanza del destino** (`Prog.route_score()`), visible en la pestaña Misiones:

| Decisión | Efecto en la balanza |
|---|---|
| Perdonar a un Arconte | +2 |
| Ejecutar a un Arconte | −1 |
| Cada recuerdo recuperado | +1 |
| Jurar lealtad a un Arconte | −1 |
| Conservar 7 o más plumas | +1 |
| Quedarse con 3 plumas o menos | −1 |

- **ALAS ABIERTAS** (balanza ≥ 0): romper la Espiral y liberar a los caídos.
- **EL TRONO VACÍO** (balanza < 0): ocupar el trono y ser el nuevo Arquitecto.

Diseño completo: documento `GDD_Seraphall.md` del Proyecto de claude.ai.
