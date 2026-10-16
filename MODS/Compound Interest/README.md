# Extra Jokers

Mod `incremental_joker` 1.1.0; prefijo `incj`. Conserva la identidad y el Joker original.
Integrado en Balatrón con Steamodded **1.0.0-beta-1224a** y Lovely **0.10.0**.

Los cinco Jokers de `run_jokers.lua` usan pools, descubrimiento y guardado nativos:

| Joker | Rareza | Precio | Efecto |
| --- | --- | --- | --- |
| Recaudador | Uncommon | $5 | +1 Mult permanente por Overkill |
| Hipster | Rare | $8 | X2 Mult para las manos menos jugadas (incluye 0 usos), incluidos empates |
| Récord Mundial | Uncommon | $6 | +6 Mult por nuevo récord de una mano de la run |
| Exceso de Fuerza | Rare | $8 | Empieza X1; +X0,1 por Overkill de ×10 o superior |
| Coleccionista | Uncommon | $6 | +3 Mult por modificación distinta presente en la baraja |

Hipster lee `G.GAME.hands[].played` antes de la mano actual (el motor ya la ha
incrementado en `joker_main`); incluye manos ocultas y nunca jugadas. Coleccionista
deduplica mejoras mediante `SMODS.get_enhancements`, sellos, ediciones y stickers
registrados. No cuenta flags internos, cartas repetidas ni mutaciones globales.
Overkill y récord emiten contextos desde `portrait_score`; los incrementos usan
`PortraitGameplay.real/once` y `ability.extra`. Copias Blueprint puntúan, sin
duplicar crecimiento. Récord Mundial mejora después de resolver la mano récord; su recibo identifica la
mano con el contador nativo, aunque se vuelva a notificar con otra puntuación.
Blueprint y Brainstorm copian la puntuación, no los incrementos. Los tres Jokers
acumulativos excluyen Perishable como sus equivalentes vanilla; Hipster y
Coleccionista lo admiten. Todos usan Editions, Eternal, Rental y eliminación nativos.
Los switches nuevos se añaden a preferencias; una run antigua conserva su snapshot.
Sprites 71×95 / 142×190 en `assets`; originales y prompts en `art-source`, excluidos
de la IPA. QA dirigida: `balatron/tests/run_jokers_qa.lua` y `--run-jokers` del
harness existente; reanudación real con `--resume`.

## Interés compuesto (sin cambios de comportamiento)

- Empieza en X1,00. Cada ciega jugada y ganada añade 0,15: `1 + 0,15 × victorias`.
- Multiplica el Mult durante `joker_main`. Crece en la evaluación principal del
  cierre de ronda, después de puntuar. Guarda contador y última ronda por carta.
- Precio base $10. Una única tirada `pseudorandom('incj_normal_shop_offer') < 0.01`
  por oferta nueva normal que ya sea Joker y resulte elegible. Incluye rerolls.
- Excluye ofertas forzadas, tutorial, etiquetas y otras rarezas impuestas. No entra
  en los pools aleatorios de sobres ni de otros generadores. Respeta vetos,
  desbloqueo, duplicados y Showman; se conservan ediciones y descuentos normales.
- Blueprint/Brainstorm copian el factor, sin crecimiento adicional. Una duplicación
  real copia el progreso con su propia tabla. Comprar otra instancia empieza en X1.
- Inglés, español de España y de México; descripción con valores reales.
- Visible en Collection → Jokers desde el inicio, desbloqueado y no descubierto.
  La primera adquisición en una partida normal usa el descubrimiento nativo,
  guardado en `meta.jkr` del perfil. No se fuerza ni se reinicia ese estado al
  arrancar; los perfiles que ya lo tienen descubierto conservan su progreso.
  La elegibilidad del 1 % depende del desbloqueo, nunca del descubrimiento.

## Ajustes

Editar `settings.lua` y recompilar el proyecto con `BUILD-IOS.ps1`:

```lua
initial_xmult = 1.0
growth_per_round = 0.15 -- incremento por ciega ganada
shop_probability = 0.01 -- 1 %, solo ofertas elegibles de Joker
base_cost = 10
debug = false
```

Solo con `debug=true` se expone `IncJoker.debug_spawn()` para desarrollo.
La IPA entregada mantiene `false`; no hay apariciones garantizadas.

## Archivos e instalación

`main.lua`: registro de atlas/Joker, descripción, puntuación y tienda.
`logic.lua`: reglas compartidas por producción y pruebas.
`lovely.toml`: inserta la tirada en la ruta normal de Steamodded antes de crear
la oferta; conserva todos los demás argumentos de creación.
`mod.json`, `settings.lua`, `localization/`, `assets/1x/` y `assets/2x/` completan el mod.

El empaquetador incorpora esta carpeta en `game.love/install_mods/incremental_joker`.
El arranque instala en el directorio real `Documents/game/Mods/incremental_joker`
antes de cargar `main.lua`; el mismo mecanismo instala Steamodded. No es necesario
copiar manualmente archivos al teléfono. Los sellos SHA-256 permiten actualizar
los recursos incluidos, sin borrar el perfil ni los guardados.

`arte_original.png` conserva la última imagen suministrada. Los sprites RGBA son
71×95 y 142×190; el encuadre y hashes están en `art-manifest.json`.
Regenerar con `python tools/build_compound_interest_art.py` desde el proyecto.
El generador recorta el fondo exterior y conserva la proporción y el interior.
El original de alta resolución y los documentos no se incluyen en la IPA.

## Pruebas

Consultar `balatron/INFORME-PRUEBAS.md` y
`validation-output/compound-interest-report.json`: reglas, simulación de 100.000
ofertas, juego real de escritorio con Lovely/Steamodded, copia, compra/venta,
reinicio de proceso, tienda y gráficos. La prueba física en iPhone está pendiente.
