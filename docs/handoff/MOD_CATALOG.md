# Catálogo de mods y contenido personalizado

Inventario preparado el 26-10-2026 leyendo las definiciones y localizaciones de
`MODS/`, `balatron/src/expansion48/` y el build. Las rutas se dan desde la raíz.
Las mecánicas/desbloqueos están resumidos; las localizaciones `es_ES`, `es_419`
y `en-us` son la referencia textual exacta.

## Alcance y cómo leerlo

- El builder copia los nueve paquetes indicados abajo desde `MODS/` (ver
  `balatron/build.py::_bundled_mods()`). `MODS/Black Market/` en raíz solo
  contiene imágenes de concepto; el Black Market activo es parte de Events.
- Sprite Joker usual: 71×95 en `assets/1x/` y 142×190 en `assets/2x/`.
- `Mxx/Cxx/Bxx/Jxx` son los 48 elementos registrados en
  `balatron/src/expansion48/catalog.lua`: 20 Mutations, 10 Contracts, 6
  Contraband y 12 Jokers. El catálogo guarda descripción, misión, arte y
  dependencias; el mod propietario registra sus sprites.
- Desbloqueado no significa garantizado en tienda: aún aplican pool, rareza,
  peso, bans, configuración y requisitos de la run.
- Este listado describe el checkout fuente, incluidos los diffs locales sin
  confirmar. No demuestra que la última IPA contenga esos diffs ni que todo se
  haya probado en iPhone. Ver `CURRENT_STATE.md`.

## Paquetes activos

| Carpeta | Contenido principal |
| --- | --- |
| `MODS/Compound Interest/` | Interés compuesto, Jokers adicionales, Doubles, misiones y Jokers expansion48. |
| `MODS/UPG JOKERS/` | Jokers evolucionables, rareza/configuración y progreso de etapas. |
| `MODS/RISK JOKERS/` | Rareza RISK, Jokers con trade-offs y misiones. |
| `MODS/Joker Fusion/` | Recetas, cartas resultado, colección, historial y FX. |
| `MODS/Deck Mutations/` | Modificadores de run, progresión y UI de Mutations. |
| `MODS/Contracts/` | Contracts de run, condiciones, recompensas y progreso. |
| `MODS/Events/` | Framework Events, tienda Black Market, Dealer y Contraband. |
| `MODS/Horizons/` | Bosses, Challenges, Vouchers, Tags, Packs y Decks. |
| `MODS/Gameplay Core/` | APIs compartidas para gameplay/UI/tracking; sin coleccionables propios. |

## Jokers: Compound Interest / Extra Jokers

Las definiciones se reparten entre `main.lua`, `run_jokers.lua`, `options.lua`,
`double_jokers.lua`, `precision_jokers.lua`, `mission_jokers.lua` y
`expansion48.lua`. Los Jokers normales se registran desbloqueados/no descubiertos,
sujetos al toggle/pool. Los que tienen misión mantienen el texto locked en
Collection. Para las filas con ruta abreviada `.../archivo.png`, la carpeta base
es `MODS/Compound Interest/assets/1x/` (su espejo 2x también está presente).

| Joker | Efecto | Desbloqueo | Sprite 1x |
| --- | --- | --- | --- |
| Interés compuesto | X1 inicial; +X0,15 por ciega jugada y ganada. 1% por oferta elegible de Joker normal en tienda. | Desbloqueado desde el inicio, no descubierto hasta primera adquisición normal. | `.../compound_interest.png` |
| Recaudador | +1 Mult permanente por Overkill. | De inicio, Uncommon. | `.../tax_collector.png` |
| Hipster | X2 Mult si la mano está entre las menos jugadas, incluidos empates y cero usos. | De inicio, Rare. | `.../hipster.png` |
| Récord Mundial | +6 Mult cuando una mano bate su récord en la run. | De inicio, Uncommon. | `.../world_record.png` |
| Exceso de Fuerza | X1 inicial; +X0,1 por cada Overkill ≥×10. | De inicio, Rare. | `.../excessive_force.png` |
| Coleccionista | +3 Mult por cada tipo distinto de Enhancement, Seal, Edition o sticker en la baraja. | De inicio, Uncommon. | `.../collector.png` |
| Olímpico | Gana X0,3 por cada récord de mano consecutivo; pierde la racha si no lo bate. | De inicio. | `.../olympico.png` |
| Options | Cada mano genera dos efectos aleatorios (Chips, Mult, XMult, dinero, interés o combo); A/B deja escoger cuál puntúa y se puede alternar por toque. | De inicio; familia Doubles configurable. | `.../options.png`, estados `options_a.png`, `_b.png`, `_base.png` |
| Todo al Color | Double: un modo premia cartas rojas puntuantes; el otro, negras. | De inicio; familia Doubles configurable. | `.../color_call.png` y variantes `_a/_b/_base.png` |
| Doble Entrada | Double: débito = +30 Mult por $1 cada mano; crédito = +$3 al terminar ciega. | De inicio; familia Doubles configurable. | `.../double_entry.png` y variantes `_a/_b/_base.png` |
| Francotirador | +X0,25 permanente al ganar con score entre 100% y 110% del objetivo. | De inicio. | `.../sniper.png` |
| Segundo Plato | +25 Mult la segunda vez que juegas cada tipo de mano durante la misma ciega. | De inicio. | `.../second_course.png` |
| Injerto | Descarta una carta mejorada para guardar su Enhancement y aplicarlo a una básica puntuante. | Puntúa cartas con 3 Enhancements distintos en una mano. | `.../graft.png` |
| Entreacto | Primer consumible durante cada ciega devuelve +1 mano y +1 descarte. | Usa 5 consumibles durante ciegas en una partida. | `.../intermission.png` |
| Entre bastidores | Aparta hasta 5 cartas del mazo en cada tienda para la siguiente ciega. | Gana con ≤35 cartas y sin añadir playing cards a la baraja durante esa run. | `.../backstage.png` |
| Péndulo | Modo A puntúa 0 y guarda Chips; modo B añade la reserva y la vacía. | En un Boss Ante 6+, juega una mano ≤1% objetivo y luego una ≥2× objetivo. | `.../pendulum.png` y `_a/_b/_base.png` |
| Entre líneas | Cartas jugadas no puntuantes activan efectos de carta mantenida durante scoring. | Boss Ante 6+ con High Card, juega 5 cartas y mantén 3 Steel. | `.../between_lines.png` |
| Chincheta | Fija una carta puntuante superviviente para jugarla en la mano siguiente; ocupa plaza. | 3 Boss consecutivos con el mismo Rey físico en sus manos ganadoras. | `.../thumbtack.png` |
| Prórroga | Al llegar al objetivo puedes seguir jugando y luego cobrar seleccionando el Joker. | Vence Boss Ante 6+ en última mano y con Overkill ≥10. | `.../extra_time.png` |
| Mercachifle | Una vez por tienda intercambia Joker propio por Joker ofertado de rareza igual o menor, sin compra/venta. | Entre dos Boss renueva ≥3 Jokers con gasto neto ≤$6 y vence segundo Boss Ante 6+. | `.../barterer.png` |
| Enroque | Una vez por ciega intercambia rangos de 2 cartas de mano, conserva sus demás propiedades. | Convierte 3 Ases físicos en doses con Strength; vence Boss Ante 6+ con trío de doses que los incluya. | `.../castling.png` |
| Pararrayos | Redirige a la carta puntuante más a la izquierda repeticiones destinadas a otras cartas jugadas. | Una carta puntúa 6 veces en mano ganadora de Boss Ante 6+. | `.../lightning_rod.png` |
| Última función | Jokers que se autodestruyen conservan su último estado útil hasta terminar la siguiente ciega elegida. | Pierde 2 Jokers por autodestrucción en un Ante y vence Boss Ante 6+. | `.../last_performance.png` |
| Letra de cambio | Al completar Contract elige su premio o repite el tipo de premio del Contract previo. | Completa 3 Contracts con 3 premios distintos sin fallos entre ellos y vence Boss Ante 6+. | `.../promissory_note.png` |
| Disco rayado | Reutiliza primeros resultados Lucky y Glass de cada carta durante toda la ciega. | Mano ganadora de Boss: ≥8 activaciones Lucky y ≥$40 obtenidos. | `.../broken_record.png` |

Los nombres de la tabla usan ruta abreviada solo en esta sección; las imágenes
Double incluyen estados adicionales porque el Joker tiene modo visible.

## Jokers RISK

`RISK` es una rareza configurable de pool ponderado. Siete entradas son pool
normal Risk; las dos últimas exigen misión. Arte bajo
`MODS/RISK JOKERS/assets/1x/` y 2x equivalente.

| Joker | Efecto | Desbloqueo | Sprite |
| --- | --- | --- | --- |
| Joker Ruso | XMult configurable; puede destruirse al ganar cada ciega. | Pool RISK. | `russian_joker.png` |
| Mecha Ardiente | XMult decae al ganar ciegas; al llegar al mínimo se destruye al volver a ganar. | Pool RISK. | `burning_fuse.png` |
| Codicia | XMult; cobra dinero por cada mano que entra en scoring. | Pool RISK. | `greed.png` |
| Cañón de Cristal | XMult alto; se destruye si la primera mano no derrota la ciega. | Pool RISK. | `glass_cannon.png` |
| Todo o Nada | XMult en primera mano; si no vence, pierde XMult permanentemente hasta mínimo. | Pool RISK. | `all_or_nothing.png` |
| Préstamo Usurero | X3,5 inicial; al ganar paga $4 o pierde X0,5 si no puede pagar (mín. X1). | Pool RISK. | `loan_shark.png` |
| Sobrecalentado | X3 al inicio de cada ciega; baja X0,4 por mano hasta X1. | Pool RISK. | `overheated.png` |
| Tierra Quemada | XMult; al final de mano destruye cartas puntuadas no protegidas. | Destruye 12 playing cards en una run. | `scorched_earth.png` |
| Barril de Pólvora | Duplica el objetivo de la ciega antes de cada mano. | Derrota Boss con última mano y score ≥2× objetivo. | `powder_keg.png` |

Comprueba `core/registry.lua` y `art_available`: la localización puede incluir
fallback «sprite pendiente» aunque una entrada no sea elegible para pool.

## Jokers UPG evolucionables

`MODS/UPG JOKERS/` registra cuatro familias base y Spyglass de expansión48.
Las etapas son el mismo objeto y guardan progreso en `ability.extra`.

| Familia/etapas | Efecto y progreso | Desbloqueo | Sprite |
| --- | --- | --- | --- |
| Metamorphosis: Larva → Chrysalis → Moth | +Mult, luego X1,5 y X3; cambia de etapa tras 4 ciegas ganadas por fase. | De inicio según registro. | `assets/1x/metamorphosis.png` (3 frames) |
| Bottomless: Hambriento → Famélico → Devorador | Acumula Mult por cartas destruidas; evoluciona a umbrales configurables y termina con XMult. | De inicio según registro. | `assets/1x/bottomless.png` (3 frames) |
| Wayfinder: Brújula → Carta Náutica → Horizonte | Repite primera, luego primera/última y al final todas las cartas puntuantes; explora tipos de mano. | Juega 5 tipos de mano distintos en un Ante. | `assets/1x/wayfinder.png` (3 frames) |
| Orrery: Sextante → Armilar → Firmamento | Cada Planet sube nivel a 1/2/3 otras manos visibles de menor nivel; evoluciona tras 5 y 12 usos. | Usa 4 Planets distintos en una partida. | `assets/1x/orrery.png` (3 frames) |
| Spyglass: Catalejo → Telescopio → Observatorio | Una vez por ciega mira/reordena top 3/5/7 del mazo; evoluciona tras 3 y 7 ciegas distintas. | Vence dos Boss consecutivos con Straight Flush. | `assets/1x/spyglass_1.png`, `_2.png`, `_3.png`; atlas `spyglass.png` |

Consulta `jokers/*.lua`, `core/evolution.lua`, `config.lua` y
`localization/es_ES.lua` para umbrales/costes exactos.

## Joker Fusion

No hay misión de perfil adicional: la receta aparece al tener los dos componentes
requeridos y poder usar la acción Fusion. Al completarla, se descubre y registra
el resultado. Los centros de fusión no entran en pool aleatorio normal.
Configuración: `MODS/Joker Fusion/config.lua`; lógica: `recipes.lua`, `core.lua`,
`jokers.lua`. Arte en `assets/1x/` y `assets/2x/`.

| Resultado | Receta | Efecto | Sprite |
| --- | --- | --- | --- |
| Fotocopiadora Rota (`broken_copier`) | Blueprint + Joker | Copia valores numéricos compatibles del Joker a la derecha; +10% eficiencia por Boss, máximo 100%; XMult escala solo la parte sobre X1; dinero se redondea abajo. | `broken_copier.png` |
| Midas | Codicia + Joker Dorado | X2 Mult; tras ciega ganada da $1 por cada $10 que tengas, máximo $8. | `midas.png` |
| Cañón Banana | Cañón de Cristal + Gros Michel | X6 Mult; se destruye con probabilidad 1/8 al ganar, 1/16 si vence con primera mano. | `banana_cannon.png` |
| Glitch | Abstract Joker + Misprint | Al comienzo de cada ciega revela +40 Mult, X2 Mult, +150 Chips, o +20 Mult y X1,5. | `glitch.png` |
| Última Cena | Mecha Ardiente + Ramen | X5; pierde X0,25 por ciega hasta X1,5; consumible recupera X0,1 hasta X5. | `last_meal.png` |

Sprites fuente/originales en `MODS/Joker Fusion/source/`; no son los PNG del
atlas de runtime.

## Expansión 48 (48 piezas con misiones)

Metadatos de verdad: `balatron/src/expansion48/catalog.lua`; reglas y evaluación
en `balatron/src/expansion48/`. El registro dueño incluye la definición concreta
y ruta de sprite. El campo `art` del catálogo se refleja aquí como guía del
motivo, no como prueba visual de cada píxel.

### 20 Mutations expansion48

Iconos 64×64 en `MODS/Deck Mutations/assets/1x/run_rules/<key>.png` y 2x.

| ID / nombre | Efecto | Desbloqueo de perfil |
| --- | --- | --- |
| M01 Doble fondo | Una carta guarda 2 Enhancements; al poner tercera se elige cuál reemplazar. | Boss Ante 6+ con las 8 Enhancements vanilla representadas en la baraja. |
| M02 Mesa de trabajo | En tienda, Tarot dirigido puede seleccionar objetivos de todo el mazo. | Modifica 12 cartas físicas con Tarot y gana Boss Ante 6+ en esa run. |
| M03 Carrusel | El reroll permite renovar fila de artículos o la de Boosters. | Durante un Ante compra ≥4 packs, ningún Joker, y vence sus 3 ciegas sin saltar. |
| M04 Mercado de futuros | Por tienda hipoteca hasta 2 manos de siguiente ciega por $8 cada una. | Boss Ante 6+ ganado con deuda legal ≥$10 tras scoring. |
| M05 Libre interpretación | Escoge qué mano válida de las cartas seleccionadas se resuelve. | 4 ciegas seguidas, 4 tipos de mano ganadora; la cuarta Boss Ante 6+. |
| M06 Entrada doble | Gana Small/Big y elige Skip Tag en lugar del cashout. | Salta Small y Big de Antes 6 y 7; vence Boss Ante 8. |
| M07 Trasvase | Tras Boss pasa hasta 3 niveles entre manos visibles, mínimo nivel 1. | Boss Ante 6+ con dos manos de nivel ≥12. |
| M08 Linaje | Copias futuras comparten cambios de rango/palo/Enhancement/Seal/Edition. | Boss Ante 6+ con 5 cartas idénticas en rango/palo/Enhancement/Seal; requiere Enhancement y Seal. |
| M09 Vale por otra | Conserva hasta 2 selecciones sobrantes para el pack siguiente. | Omite 2 Mega Packs de distintas familias y gana ese Boss sin comprar Jokers ese Ante. |
| M10 Gravedad inversa | Efectos de cartas mantenidas ocurren antes que los de jugadas. | Boss Ante 6+ manteniendo 5 Steel. |
| M11 Lista negra | Retira Joker ofertado y veta su centro de futuras ofertas aleatorias en la run. | Gana una run teniendo solo Jokers Common en cada victoria. |
| M12 Función de noche | Alquila Joker de tienda a 1/3 de precio, redondeo arriba, hasta fin de ciega siguiente. | 3 ciegas seguidas con Joker comprado desde victoria previa y vendido en tienda posterior. |
| M13 Cláusula suspensiva | Cada Contract fallido reintenta una vez, con términos y premio iguales. | Falla Contract; completa 2 seguidos sin nuevo fallo; vence Boss Ante 6+. |
| M14 Fondo de garantía | Apuesta Contract reward: siguiente completion lo duplica; un fallo la pierde. | Completa 3 Contracts seguidos y vence Boss Ante 6+ con ≥$40. |
| M15 Piezas intercambiables | Sustituye componente de Fusion por Joker de igual rareza pagando $6. | En una run, Fusion con componente de pack y otra con uno de tienda. |
| M16 Diezmo | Dinero de habilidades durante ciega se suma a score al 2% del objetivo por $1. | Gana ≥$25 con habilidades durante una ciega y véncela. |
| M17 Contrapunto | Mano combina Chips base de mano actual con Mult base de la anterior distinta de esta ciega. | Boss Ante 6+ jugando exactamente A–B–A–B con dos tipos de mano. |
| M18 Consigna | Guarda hasta 3 Tags nuevos y actívalos después en fase normal. | Activa 3 Tags de tienda distintos en una tienda y vence el Boss del Ante. |
| M19 Muda | Tras Boss cambia Mutation propia por una de 3 alternativas elegibles. | Gana sin conservar ningún Joker de entrada a Ante 4; al entrar tenía ≥3. |
| M20 A domicilio | Compra y guarda un pack sin abrir; puede abrirlo entre manos; máximo uno. | Boss Ante 6+ tras usar 4 consumibles durante esa ciega, sin comprar consumibles/packs en tienda previa. |

Claves exactas de sprite para `<key>`: M01 `false_bottom`, M02 `workbench`, M03
`carousel`, M04 `futures_market`, M05 `open_interpretation`, M06
`two_way_ticket`, M07 `decanting`, M08 `bloodline`, M09 `rain_check`, M10
`reverse_gravity`, M11 `blacklist`, M12 `one_night_engagement`, M13
`stay_of_execution`, M14 `escrow`, M15 `spare_parts`, M16 `tithe`, M17
`counterpoint`, M18 `left_luggage`, M19 `molting`, M20 `takeaway`.

### 10 Contracts expansion48

PNG 1x/2x bajo `MODS/Contracts/assets/{1x,2x}/expansion/<key>.png`.
Son contratos ofertados/aceptados durante una run; unlock indica Collection.

| ID / nombre | Condición del contrato | Desbloqueo |
| --- | --- | --- |
| C01 Cambio de reparto | Gana 2 siguientes ciegas con ≥3 Jokers; no conserva en la segunda ninguno de los Jokers físicos de la primera. | Vende Joker Rare con Edition y gana 2 Boss sin readquirir el centro. |
| C02 Embargo | Gana próximas 3 ciegas sin comprar ni rerollear. | Completa Ante 6 sin saltos ni gasto en las 3 tiendas. |
| C03 Sin bis | Gana próxima ciega con ≥2 manos sin repetir rangos puntuados entre ellas. | 2 ciegas consecutivas con mano ganadora de 5 cartas y rangos distintos. |
| C04 Caja registradora | Gana ≥$12 con habilidades de playing cards durante próxima ciega y véncela. | Gana ≥$30 por habilidades en un Ante y vence Boss Ante 6+. |
| C05 Puesta de largo | Elige mano que aún no jugaste y gana próximo Boss con ella. | Boss Ante 6+ con mano nivel 1 mientras otra está a nivel ≥10. |
| C06 Última fila | Puntúa una de 3 cartas inferiores señaladas en la primera mano; gana ciega. | Juega 30 cartas físicas distintas en ciega y véncela con 0 descartes. |
| C07 Efecto dominó | Una carta física puntúa 6 veces en mano ganadora de próxima ciega. | Boss Ante 6+ con una carta que puntúe ≥5 veces y 3 fuentes de retrigger. |
| C08 Silencio administrativo | Jokers debuffados durante próxima ciega; debe ganarse. | Vence Boss Ante 5 y 6 sin tener Jokers en ninguna de las dos. |
| C09 Testigos protegidos | Elige 3 cartas del robo inicial y no las juegues, descartes ni destruyas; gana. | Boss Ante 6+ manteniendo 4 Gold desde el robo inicial. |
| C10 Capital semilla | Compra Joker y revéndelo por ≥$8 de beneficio antes del 2.º Boss desde aceptación. | Vende Egg por ≥$30 y gana el Boss de ese Ante. |

Sprite filenames por orden C01–C10: `recasting.png`, `embargo.png`,
`no_repeat.png`, `cash_register.png`, `debut.png`, `back_row.png`,
`domino_effect.png`, `administrative_silence.png`, `protected_witnesses.png`,
`seed_capital.png` en `MODS/Contracts/assets/1x/expansion/` (y homólogos 2x).

### 6 Contraband expansion48

Arte en `MODS/Events/assets/{1x,2x}/contraband/<key>.png`.

| ID / nombre | Efecto | Desbloqueo |
| --- | --- | --- |
| B01 Orden de desmontaje | Desmonta Fusion propio y recupera los dos componentes base; elige quién conserva Edition. | Boss Ante 6+ con dos Fusions de recetas distintas a la vez. |
| B02 Quitamanchas | Retira Eternal, Rental y Perishable de Joker propio. | Boss Ante 6+ con dos Perishable agotados todavía ocupando slots. |
| B03 Fe de vida | Recupera una de las 3 últimas playing cards destruidas con sus propiedades; va al fondo del mazo. | Destruye carta con Enhancement+Seal+Edition y vence ese Ante un Boss Ante 6+. |
| B04 Diploma falso | Avanza inmediatamente una etapa de Joker UPG propio. | Lleva dos familias UPG a etapa final y vence Boss con ambas. |
| B05 Vuelco | Intercambia mazo restante y pila de descarte, no cambia mano. | Vence Boss Ante 6+ tras agotar el mazo. |
| B06 Coartada | Escoge tipo de mano; hasta fin de Ante Jokers ignoran usos anteriores, pero nuevos usos cuentan. | Vence Bosses Ante 7 y 8 con Obelisk; no juegues mano más usada al entrar Ante 7 (≥10 usos). |

Sprite filenames B01–B06 por orden: `disassembly_order.png`, `stain_remover.png`,
`proof_of_life.png`, `fake_diploma.png`, `turnover.png`, `alibi.png` bajo
`MODS/Events/assets/1x/contraband/` (y 2x equivalente).

## Events / Black Market / Contraband base

Events registra Black Market con configuración por defecto de 5% de aparición,
pity +1% hasta 20%, multiplicador de precio 1,5× y heat según compra/uso. Fuente:
`MODS/Events/config.lua`, `black_market/`. Los diez Contraband base no declaran
misión de Collection; aparecen en el pool según weights y condiciones.
Sprites bajo `MODS/Events/assets/{1x,2x}/contraband/`.

| Contraband | Efecto resumido | Sprite 1x |
| --- | --- | --- |
| Dados Cargados (`loaded_dice`) | Duplica comprobaciones de éxito para Lucky y Wheel of Fortune durante Ante. | `loaded_dice.png` |
| Vale Falsificado (`counterfeit_voucher`) | Elige Voucher elegible que todavía no posees. | `counterfeit_voucher.png` |
| Carta Marcada (`marked_card`) | Elige playing card; reemplaza Enhancement y Seal por resultados mostrados, preserva Edition. | `marked_card.png` |
| Información Privilegiada (`inside_information`) | Previsualiza próxima tienda y reserva un objeto. | `inside_information.png` |
| Negativo Robado (`stolen_negative`) | Aplica Negative a Joker propio sin Edition. | `stolen_negative.png` |
| Falsificación (`forgery`) | Copia consumible propio no-Contraband; usa el slot liberado. | `forgery.png` |
| Elección del Dealer (`dealers_choice`) | Elige hasta uno de 3 Jokers Rare con odds normales de Edition. | `dealers_choice.png` |
| Mercancía Caliente (`hot_merchandise`) | Elige uno de hasta 3 Jokers con Edition garantizada. | `hot_merchandise.png` |
| Soborno (`bribe`) | Elige Boss válido y sustituye el Boss del Ante; usar antes de entrar. | `bribe.png` |
| Etiqueta Robada (`stolen_tag`) | Elige Tag válido y lo recibe sin saltar ciega. | `stolen_tag.png` |

La localización de Events también contiene Coartada, Orden de desmontaje,
Quitamanchas, Fe de vida, Diploma falso y Vuelco; son B01–B06 arriba. La raíz
`MODS/Black Market/` no es la carpeta fuente de ejecución.

## Contracts base

Los siete Contracts base se ofertan desde la infraestructura del mod activado.
La UI usa atlas `MODS/Contracts/assets/1x/contracts.png` (128×128 por celda),
no un PNG independiente por cada Contract. Condiciones exactas de duración,
objetivo y fallback de premio están en `MODS/Contracts/contracts.lua`,
`config.lua`, `localization/es_ES.lua`.

| ID / nombre | Objetivo y recompensa |
| --- | --- |
| `clean_hands` · Manos limpias | Gana ciegas consecutivas sin descartar; dinero. |
| `one_shot` · Un solo tiro | Gana próxima ciega en una mano; Joker Uncommon+ o dinero si no hay candidato/espacio. |
| `monochrome` · Monocromo | Gana próxima ciega con un solo palo puntuado; dinero y Tarot si cabe. |
| `high_roller` · Gran apostador | Gasta objetivo en siguiente tienda; recompensa rerolls en tienda posterior. |
| `no_safety_net` · Sin red | Gana próximo Boss sin consumiribles esa ciega; recompensa Spectral. |
| `execution` · Contrato de ejecución | Destruye objetivo de cartas en Ante; puede dar Hanged Man Negative al aceptar; dinero al completar. |
| `debt_collector` · Cobrador de deudas | Termina Ante con saldo objetivo; paga dinero. |

## Deck Mutations base, reglas y progreso

Las 19 mutations base están en `MODS/Deck Mutations/mutations.lua`. Su arte usa
atlas `assets/1x/mutations.png`; `overload.png`, `resonance.png` y
`chain_reaction.png` tienen atlas propios. `run_rules.lua` contiene 49 reglas
adicionales de economía, tienda, scoring, odds y packs; `expansion.lua` agrega 11
y `expansion48.lua` define las 20 M01–M20 de arriba. Las reglas tienen sprites
64×64 en `assets/1x/run_rules/<id>.png` y 2x.

| Mutation base | Efecto resumido |
| --- | --- |
| Bolsillos profundos (`deep_pockets`) | +1 tamaño de mano. |
| Segunda oportunidad (`second_chance`) | +1 mano por ciega. |
| Manos sueltas (`loose_hands`) | +1 descarte por ciega. |
| Techo Alto (`interest_rate`) | Eleva tope de interés. |
| Corazones pesados (`heavy_hearts`) | Corazones puntuados dan Chips. |
| Picas afiladas (`sharp_spades`) | Picas puntuadas dan Mult. |
| Sangre real (`royal_blood`) | J/Q/K puntuadas dan Chips. |
| Bajos fondos (`low_life`) | 2–5 puntuados dan Mult. |
| Doble Fondo (`bigger_pockets`) | +1 espacio de consumibles. |
| Mutagénesis (`enhanced_genetics`) | Opción de crear playing card mejorada. |
| Baraja afortunada (`lucky_deck`) | Mejora odds de cartas Lucky y Wheel of Fortune. |
| Hábitat de Jokers (`joker_habitat`) | +1 slot de Joker. |
| Tréboles firmes (`steady_clubs`) | Tréboles puntuados dan Mult. |
| Reserva de diamantes (`diamond_reserve`) | Diamantes puntuados dan Chips. |
| As en la manga (`ace_up_sleeve`) | Ases puntuados dan Chips. |
| Dividendo del jefe (`boss_dividend`) | Dinero al derrotar Boss. |
| Sobrecarga (`overload`) | Primera mano +100 Chips, luego baja 20 por mano hasta 0. |
| Resonancia (`resonance`) | Segunda carta puntuante consecutiva del mismo palo gana +4 Mult. |
| Reacción en Cadena (`chain_reaction`) | Secuencia de puntuación aumenta Chips de cartas siguientes. |

Requisitos persistentes/de run son fuente de verdad en
`MODS/Deck Mutations/progression.lua` y `unlocks.lua`; scope `run` exige cumplir
en la misma partida y `profile` persiste progreso. Métricas presentes incluyen
obtener 5 Jokers/Rare/Edition/Negative/RISK/Double, usar Contraband/Contracts/
Fusions/Spectrals/Planets, abrir packs, Overkill, llegar a Antes 4/6/8, ganar una
run, rerolls, ventas, interés, cartas mejoradas/con Seal y probabilidades Lucky.
Los IDs y objetivos exactos se mantienen en `progression.lua`; no copiar un
resumen de desbloqueo como texto final sin contrastar esa tabla. La configuración
puede desactivar objetos, y los cambios de config se aplican a nuevas runs.

## Horizons — 38 elementos

Fuente de catálogo: `MODS/Horizons/catalog.lua`; registros en `bosses.lua`,
`challenges.lua`, `vouchers.lua`, `tags.lua`, `packs.lua` y `decks.lua`.
Sprites 1x/2x en `MODS/Horizons/assets/<densidad>/<categoría>/<key>.png`.
Challenges tienen arte de portada `<CHxx>.png` y pequeño `<CHxx>_icon.png`.

### Boss Blinds (6)

| ID / nombre | Efecto | Unlock | Sprite 1x |
| --- | --- | --- | --- |
| BS01 La Escoba | Cada descarte elimina toda la mano. | Derrota 5 Bosses distintos. | `bosses/broom.png` |
| BS02 El Peine | Cartas jugadas puntúan de menor a mayor rango. | Gana Boss Ante 6+ con ≥4 cartas puntuantes. | `bosses/comb.png` |
| BS03 La Sordina | No puedes repetir cartas jugables. | Gana Boss repitiendo misma carta ≥4 veces en mano ganadora. | `bosses/mute.png` |
| BS04 La Laca | Editions no dan Chips ni Mult. | Posee Foil+Holographic+Polychrome y gana Boss Ante 4+. | `bosses/lacquer.png` |
| BS05 La Caja Fuerte | Aísla el dinero al entrar; lo devuelve al ganar. | Gana Boss Ante 4+ con ≥$75. | `bosses/vault.png` |
| BS06 La Bisagra | Jokers Double alternan modo después de cada mano; no se cambian manualmente. | Gana run usando los dos modos de un Double durante un Boss. | `bosses/hinge.png` |

### Challenges (8)

| ID / nombre | Regla / Unlock | Sprite 1x |
| --- | --- | --- |
| CH01 Alto horno | Solo funcionan Fusions; empiezas Abstract Joker y Misprint. Unlock: ganar run tras hacer 2 recetas Fusion distintas. | `challenges/CH01.png` + `_icon.png` |
| CH02 Deuda de sangre | Empiezas $12 y Greed anclado; mano que termina con dinero <0 pierde. Unlock: llevar Greed en últimos 3 Boss sin terminar manos con deuda; gana run. | `CH02.png` + `_icon.png` |
| CH03 Pago en especie | Compras gratis, cada compra destruye una carta; rerolls pagados. Unlock: destruye ≥15 y termina con ≤30 cartas, gana. | `CH03.png` + `_icon.png` |
| CH04 Juramento | Completa ≥1 Contract cada Ante o pierde al cerrar Boss. Unlock: 4 Contracts distintos antes de fin Ante 6 y gana. | `CH04.png` + `_icon.png` |
| CH05 Por encargo | Jokers nuevos inactivos hasta comienzo del Ante siguiente. Unlock: gana sin comprar/crear Joker desde inicio Ante 6. | `CH05.png` + `_icon.png` |
| CH06 Equipaje de mano | Jokers y consumibles comparten 5 espacios; Negative gratis. Unlock: usa ≥12 consumibles de 3 familias y gana. | `CH06.png` + `_icon.png` |
| CH07 A ciegas | Tienda oculta identidad de oferta; muestra tipo, rareza y precio. Unlock: completa X-Ray Vision vanilla. | `CH07.png` + `_icon.png` |
| CH08 Ensayo general | Efecto de Boss se aplica también a Small y Big. Unlock: gana sin cambiar/desactivar Boss y vence ≥6 Boss distintos. | `CH08.png` + `_icon.png` |

### Vouchers (8)

Todos cuestan $10. Los segundos de cada pareja amplían el primero.

| ID / nombre | Efecto | Unlock | Sprite 1x |
| --- | --- | --- | --- |
| VX01 Abrecartas | Una vez por Booster vanilla, paga $3 para sustituir una opción no elegida. | Escoge cartas en 5 packs de ≥3 familias y vence Boss Ante 6+. | `vouchers/letter_opener.png` |
| VX02 Guillotina | Abrecartas puede sustituir todas las opciones restantes por $5, un servicio por pack. | Con Abrecartas sustituye en 3 familias y gana. | `vouchers/guillotine.png` |
| VX03 Alambique | Por tienda entrega 2 Tarot o 2 Planet + $2 y elige consumible de ese set entre 3. | Usa 6 Tarot/Planet distintos en una tienda y gana ciega Ante 6+. | `vouchers/alembic.png` |
| VX04 Crisol | Alambique acepta Tarot + Planet y garantiza una Spectral en opciones. | Con Alambique realiza 3 intercambios y vence Boss Ante 8+. | `vouchers/crucible.png` |
| VX05 Costurero | Por tienda, $6 mueve Foil/Holo/Polychrome de Joker a Joker sin Edition. | Vende 3 Jokers con Editions distintas y gana Boss Ante 6+. | `vouchers/sewing_kit.png` |
| VX06 Alta costura | Costurero también mueve Editions entre playing cards y Jokers. | Con Costurero mueve 2 Editions distintas y vence Boss Ante 8+. | `vouchers/haute_couture.png` |
| VX07 Segunda opinión | Paga $3 para reemplazar oferta de Contract por otro elegible. | Completa 4 Contracts distintos sin fallar y vence Boss Ante 6+. | `vouchers/second_opinion.png` |
| VX08 Licitación | Segunda opinión compara 2 Contracts de reemplazo antes de elegir. | Con Segunda opinión completa 3 Contracts reemplazados y gana. | `vouchers/tender.png` |

### Tags (8)

| ID / nombre | Efecto | Unlock | Sprite 1x |
| --- | --- | --- | --- |
| TX01 Marcador | The Fool puede escoger entre últimos 3 Tarot/Planet usados distintos. | Recupera 3 distintos y vence Boss Ante 6+. | `tags/bookmark.png` |
| TX02 Billete de vuelta | Joker vendido vuelve a siguiente tienda con su estado; se compra de nuevo. | Vende Joker sell value ≥$20, vence Boss Ante 6+. | `tags/return_ticket.png` |
| TX03 Etiqueta cambiada | Intercambia precios de 2 objetos de la tienda principal. | Compra Joker ≥$15 y consumible ≤$3 en una tienda; vence Boss Ante 6+. | `tags/mislabel.png` |
| TX04 Despensa | Restaura desgaste de Joker de comida elegible. | Consume 3 Jokers de comida distintos; vence Boss Ante 6+. | `tags/pantry.png` |
| TX05 Vuelco | En próxima mano intercambia Chips y Mult tras cartas y antes de Jokers. | Boss Ante 6+ con ≥500 Chips y ≥100 Mult sin XMult de Joker Edition. | `tags/topsy_turvy.png` |
| TX06 Intermedio | Añade tienda antes de elegir próxima ciega; no cashout ni avance de Ante. | Boss Ante 6+ sin compras/reroll en 3 tiendas previas. | `tags/interval.png` |
| TX07 Comitiva | Permite jugar hasta 6 cartas durante siguiente ciega. | 3 Boss seguidos jugando exactamente 5 cartas en todas las manos. | `tags/procession.png` |
| TX08 Radiografía | Packs de siguiente tienda normal muestran su contenido fijado antes de compra. | Compra 4 familias de packs, omite uno y vence Boss Ante 6+. | `tags/xray.png` |

### Booster Packs (4)

| ID / nombre | Efecto | Unlock | Sprite 1x |
| --- | --- | --- | --- |
| PX01 Montaje | Escoge rango/palo de cuerpo y luego acabado nativo; añade una carta. | Añade cartas desde 3 Standard Packs; vence Boss Ante 6+ con una en mano ganadora. | `packs/montage.png` |
| PX02 Prenda | Cada Spectral se vincula a carta concreta; destruye carta y recibe Spectral real. | Destruye 5 cartas con consumibles; vence Boss Ante 6+ con ≤40 cartas. | `packs/pledge.png` |
| PX03 Escalada | Toma Joker o arriesga perderlo por subir rareza; odds 75%, luego 50%. | Compra Common, Uncommon y Rare; gana sin recibir Legendary. | `packs/escalation.png` |
| PX04 Hoja de ruta | Escoge Tags que ofrecerán Small/Big Blind próximo Ante; solo se ganan saltando. | Salta exactamente una ciega en ≥5 Antes distintos y gana. | `packs/roadmap.png` |

### Decks (4)

| ID / nombre | Efecto | Unlock | Sprite 1x |
| --- | --- | --- | --- |
| DK01 Baraja de Relevo | 6 slots de Joker; slots impares/pares activos alternadamente por ciega. | Gana Bosses de Ante 6, 7 y 8 con ≥6 Jokers. | `decks/DK01.png` |
| DK02 Baraja de Dietas | Dinero se fija en $20 al entrar a tienda y $0 al salir. | Gasta ≥$180 y termina cada Boss con ≤$5. | `decks/DK02.png` |
| DK03 Baraja Laberinto | Elige orden de las tres ciegas de Ante; no puede saltarlas. | Gana sin skips y vence Bosses con ≥4 tipos de mano distintos. | `decks/DK03.png` |
| DK04 Baraja de Mareas | Cartas puntuadas suben rango; descartadas bajan rango. | Gana tras transformar ≥8 cartas con Strength. | `decks/DK04.png` |

## Arte de barajas y otros sprites

- **Deck 1** sí se documenta integrado: skin cosmética en Options → Customize
  Deck → Card Skin, 52 caras y reverso, atlas 4x y fuentes editables. No tiene
  misión adicional de unlock. Ver `balatron/assets/skins/deck1/README.md` y
  arte fuente `DECK1/`.
- **Deck 2 / Occult Arcade:** hay imágenes, propuestas, checkpoint y un
  `integration-draft/` en `DECK 2/deck_occult_arcade/`. El README local dice que
  sigue pendiente; no anunciarlo como deck seleccionable.
- **Deck 3 / Retro Gaming:** assets/checkpoint/previews en
  `DECK 3/deck3_retro_gaming/`; igualmente no se declara integrado.
- Icono de app: máster `balatron/ios/icon-master.png`; variantes en
  `balatron/ios/Assets.xcassets/AppIcon.appiconset/`. Es arte del bundle, no
  contenido desbloqueable.
- `MODS/Black Market/` conserva concepts de arte, pero los sprites activos están
  en `MODS/Events/assets/` y se registran desde Events.

## Referencias exactas por familia

Antes de afirmar un unlock o editar sprite, comprobar estas fuentes:

- Extra Jokers: `MODS/Compound Interest/localization/es_ES.lua`, archivos
  de registro y `settings.lua`.
- RISK: `MODS/RISK JOKERS/jokers/`, `mission_jokers.lua`, `core/registry.lua` y
  `localization/es_ES.lua`.
- UPG: `MODS/UPG JOKERS/jokers/`, `core/evolution.lua`, `README.md` y localización.
- Fusion: `MODS/Joker Fusion/recipes.lua`, `core.lua`, `jokers.lua`, `config.lua`.
- Expansion48: `balatron/src/expansion48/catalog.lua`, `missions.lua` y el módulo
  propietario del ID.
- Horizons: `MODS/Horizons/catalog.lua` más el módulo por tipo de objeto.
- Mutations: `mutations.lua`, `run_rules.lua`, `expansion.lua`, `expansion48.lua`,
  `progression.lua`, `unlocks.lua` y `ui.lua` dentro de `MODS/Deck Mutations/`.
- Contract base: `MODS/Contracts/contracts.lua`, `config.lua`,
  `localization/es_ES.lua`; Expansion C01–C10 proviene de catálogo expansion48.
- Contraband base: `MODS/Events/black_market/contraband/` y sus localizaciones;
  B01–B06 son expansion48.
- Sprite: no basta que exista el campo `art` en un catálogo. Confirmar PNG,
  registro `SMODS.Atlas` y que `balatron/build.py::_bundled_mods()` incluya su
  carpeta de origen.

El catálogo describe lo que está en fuente; no se volvió a ejecutar una partida
para confirmar cada efecto. En particular, los 11 cambios locales sin confirmar
pueden ser posteriores a los logs/IPA citados en los informes. No prometer que
la build entregada los incluye hasta comprobar su contenido.
