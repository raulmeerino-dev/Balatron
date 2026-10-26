# IOS_AND_MODS — portrait, iOS y compatibilidad de mods

## Portrait y layout

El build está orientado a portrait y empaqueta `Info.plist` como portrait-only
según los informes. El juego calcula la composición en unidades lógicas de
LÖVE. `balatron/src/portrait_config.lua` define escalas/márgenes, `touch_target_points`
(44), umbrales de arrastre y swipes, reglas de filas, safe areas y Diagnostics.
Los valores cambian según el viewport, HUD, tamaño de inventario y orientación.
No reducir esto a un único tamaño fijo de iPhone.

El informe incluye perfiles de escritorio 375×667, 390×844 y 393×852 puntos;
para el caso 393×852 se simulan insets 59/34 y render 3x. Esos perfiles son
fixture de escritorio, no resoluciones nativas garantizadas ni evidencia de
hardware. El informe más reciente dice que Run Info se revisó en 393×852 con
ES/EN y que falta validación física.

Las acciones Jugar/Descartar permanecen disponibles; gestos configurables
permiten deslizar una carta seleccionada hacia arriba/abajo. Selección múltiple,
drag lento/rápido, long holds, cancelación y bloqueo tienen reglas de seguridad.
La UI debe usar targets táctiles y safe-area helpers ya existentes.

## Integración iOS

- Build sin Xcode/macOS a través de shell iOS precompilado ARM64 con Lovely,
  insertando `Game.love`. IPA queda unsigned para AltStore/Sideloadly.
- App **BALATRÓN**, bundle ID `com.rulo3.balatro.portrait`, independiente de la
  app oficial. Conserva ID e identidad de firma entre actualizaciones para
  mantener datos; no desinstalar al actualizar.
- `balatron/src/portrait_ios.lua` y sonda Swift bajo
  `balatron/tools/ios_inset_probe/` exponen datos UIKit/display cuando existen.
  Los valores `?` fuera de iOS son esperables.
- High-DPI/native scale y canvas se configuran en `src/conf.lua` y `src/main.lua`.
  Las coordenadas de input siguen en espacio lógico.
- El reporte de pruebas aconseja copia de `game/` antes de actualizar. El sandbox
  de esta app no importa automáticamente saves del juego oficial u otra identidad.
- El bug `/private/var` vs `/var` tuvo corrección específica; verificar rutas
  nuevas sin ampliar equivalencias a destinos distintos.

## Mods incluidos y compatibilidad

Fuentes locales: raíz `MODS/`. Se encuentran módulos como `Events`, `Horizons`,
`Gameplay Core`, `Joker Fusion`, `Deck Mutations`, `Compound Interest`, `Contracts`,
`RISK JOKERS` y `UPG JOKERS`. Cada mod tiene `main.lua`, configuración,
localización y ficheros de lógica/UI. Consultar sus READMEs y manifiestos antes
de editar. Copias de mods bajo `balatron/src/assets/` son recursos integrados,
no siempre fuente de lógica.

Para identificar qué carpeta pertenece a cada ID de Steamodded, qué categoría
representa y qué estado conserva, usa `MODS/README.md` y
`docs/handoff/MOD_CATALOG.md`. Gameplay Core registra también Roulette. Events
declara ahora su dependencia directa de Gameplay Core en `mod.json`.

El flujo personal registra Steamodded 1.0.0-beta-1224a en
`balatron/mods/Steamodded/` y Lovely 0.10.0 enlazado en shell. `portrait_mods.lua`
preinstala mods antes del arranque/loader y el instalador debe reparar copias
incompletas; `portrait_smods.lua` re-aplica integración portrait tras overrides.
No se ha demostrado compatibilidad universal con mods terceros: los patrones UI
de escritorio de Steamodded pueden divergir de portrait. El documento de mods
enumera exclusiones de patches deliberadas.

Los diffs actuales «Marked Card» modifican selección/preview/efecto de un
consumible y son trabajo en curso hasta revisión. Deben probar persistencia de
elecciones (cierre/carga), validez de carta objetivo, enhancement/seal, edición,
localización y juego sin Steamodded si la función depende de él. Confirmar que
el checkpoint no genera rerolls indeseados ni altera RNG al volver a abrir UI.

## Cambios al juego original

Se documentan cambios al layout portrait, touch input, Diagnostics, safe area,
escala/canvas, pantallas/menús para móvil, fondos de color sin reemplazar shader,
icono/identidad del bundle y contenido de mods. Los informes afirman que ciertas
funciones originales de scoring/RNG se compararon byte/función y quedaron
intactas en versiones específicas; eso no prueba igualdad de cada build futura.
No asumir que el diff completo es “solo UI”: los mods agregan contenido/gameplay.

Para evitar regresiones: respetar callbacks y hooks del juego, campos/formatos de
guardado, posibilidad de jugar en desktop, paths de empaquetado y variaciones
ES/ES-419/EN. Hacer cambios fuente pequeños y comprobar rutas/assets/sintaxis;
si el cambio altera interacción, guardado, RNG o parcheo, revisar los tests
focalizados existentes según la autorización del usuario y las instrucciones.
