# Mods locales de Balatrón

Guía de orientación para las fuentes de mods que empaqueta `balatron/build.py`.
Separa la carpeta física, el ID técnico de Steamodded, la familia del contenido y
su presentación al jugador. No implica que cada elemento listado haya sido
validado en una partida durante esta revisión.

## Paquetes activos

El builder registra explícitamente nueve carpetas. Mantén estas rutas y sus IDs
sin migración planificada: las referencias cruzadas, los perfiles de mod y los
datos guardados pueden depender de ellos.

| Carpeta fuente | ID Steamodded | Nombre visible | Prefijo | Propiedad principal |
| --- | --- | --- | --- | --- |
| `Compound Interest/` | `incremental_joker` | Extra Jokers | `incj` | Jokers adicionales, Doubles, misiones y Jokers Expansion48. El Joker homónimo sigue siendo Interés compuesto (`j_incj_compound_interest`). |
| `RISK JOKERS/` | `risk_jokers` | Risk Jokers | `risk` | Rareza RISK, Jokers de riesgo/recompensa y misiones. |
| `UPG JOKERS/` | `upgraded_jokers` | Upgraded Jokers | `upg` | Jokers evolucionables y etapas. |
| `Joker Fusion/` | `joker_fusion` | Joker Fusion | `fuse` | Recetas y centros de Joker resultado de fusión. |
| `Deck Mutations/` | `deck_mutations` | Deck Mutations | `dm` | Mutations, reglas de run, progresión y UI. |
| `Contracts/` | `contracts` | Contracts | `ct` | Contratos de run, objetivos, recompensas y progreso. |
| `Events/` | `portrait_events` | Events | `evt` | Black Market, Dealer, Contraband y sus interfaces. |
| `Horizons/` | `portrait_horizons` | Horizons | `hz` | Expansión con objetos nativos de varias categorías. |
| `Gameplay Core/` | `portrait_gameplay` | Gameplay Core | `pg` | APIs/helpers compartidos y Booster Roulette. |

El paquete técnico de Compound Interest ya se presenta como **Extra Jokers** en
`MODS/Compound Interest/mod.json`. Conserva `incremental_joker`, `incj` y las
claves de centros existentes: renombrar la carpeta o IDs puede afectar a
referencias, estados de run, descubrimientos o configuración. La familia Doubles
y su configuración independiente viven en la misma fuente.

## Categorías del juego y propiedad

Las categorías son conceptuales; no son necesariamente mods separados. Risk,
Fusion, UPG, Mutations, Contracts, Contraband, Tags y Boss Blinds mantienen el
paquete propietario descrito arriba. Horizons conserva su paquete y registra
objetos mediante tipos nativos de Steamodded; `H.decorate(def, id)` adjunta la
procedencia `def.horizons = id` y la configuración permite activar/desactivar
familias. No dupliques objetos en una colección propia ni muevas registros entre
paquetes sin trazar referencias, sprites, traducciones, perfil y guardado.

`MODS/Black Market/` en la raíz es material conceptual (imágenes), no un décimo
mod: no tiene `mod.json` ni lo enumera el builder. El contenido ejecutable de
Black Market/Dealer/Contraband pertenece a `MODS/Events/`. No copies las imágenes
de concepto a una carpeta runtime sin verificar el filtro de empaquetado.

### Gameplay Core y dependencias

`Gameplay Core` proporciona `PortraitGameplay` y helpers compartidos. Varias
fuentes los llaman desde sus módulos. `Events` consume Core directamente tanto
desde la UI de consumibles como al cargar Expansion48; por ello su manifiesto
declara `portrait_gameplay (>=1.0.0)`. No confíes únicamente en `priority` para
ordenar dependencias. Otros accesos opcionales desde Events a Run Rules, Risk,
UPG y Fusion tienen comprobaciones condicionales en el código revisado; vuelve a
verificar cada uso antes de convertirlo en dependencia obligatoria.

Gameplay Core también registra el Booster `p_pg_roulette` en
`MODS/Gameplay Core/roulette.lua`; no describirlo como infraestructura sin
contenido propio.

## Expansion48 y estado persistente

`balatron/src/expansion48/catalog.lua` es el índice compartido de 48 IDs únicos:
20 Mutations (`Mxx`), 10 Contracts (`Cxx`), 6 Contraband (`Bxx`) y 12 Jokers
(`Jxx`). La entrada del catálogo conecta misión, categoría, propietario y guía
de arte; cada mod propietario registra el objeto real y su atlas. Infraestructura
común y evaluación están en `balatron/src/expansion48/`.

Antes de tocar contenido, guarda exactamente las claves ya usadas: ID/código de
catálogo, `key` de centro SMODS, prefijo de localización, metadatos
`expansion48`/`exp48_id`, configuración y recibos de progreso en perfil/run.
Una migración de IDs requiere plan y comprobación explícita; no hagas una
limpieza de nombres como parte de un cambio visual.

## Rutas y reglas de recursos

- Manifiesto, punto de entrada y prefijo: `MODS/<paquete>/mod.json`.
- Código de registro: `main.lua` y módulos declarados/cargados desde él.
- Localización: `localization/`; comprobar claves en ES/EN además del registro.
- Sprite runtime: `assets/1x/`, `assets/2x/`; un PNG suelto no demuestra que se
  registre. Confirma la ruta, `SMODS.Atlas`, referencia de centro y resolución.
- Arte fuente puede estar en `art-source/`, `source/`, carpetas de conceptos o
  fuera del paquete. `balatron/build.py::_bundled_mods()` filtra directorios y
  archivos para no incluir material de producción. No cambies esos filtros sin
  comprobar el tamaño/contenido empaquetado y el README de build.
- Catálogo detallado de contenido, desbloqueos y rutas de sprites:
  `docs/handoff/MOD_CATALOG.md`.

## Comprobaciones antes de editar

1. Lee `AGENTS.md`, `docs/handoff/` y este archivo.
2. Comprueba `git status` y el diff; trabaja en la fuente raíz `MODS/`, no en
   `local-archive/` ni en copias archivadas.
3. Traza manifiesto → `main.lua` → registro → atlas/sprite → localización →
   unlock/config/save y dependencias compartidas.
4. No cambies balance, RNG, IDs ni estructura persistente en una tarea de orden
   o UI.
5. Realiza comprobaciones focalizadas. No generes/recompiles IPA salvo petición
   literal «Genera la IPA» y no declares verificado iPhone sin hardware.

La auditoría que añadió esta guía detectó una dependencia directa de Events en
Gameplay Core y la declaró en `MODS/Events/mod.json`. No alteró reglas, IDs,
probabilidades, desbloqueos ni formatos de guardado. Las pruebas de partida y de
iOS no se ejecutaron.
