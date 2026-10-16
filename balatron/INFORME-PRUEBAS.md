# Informe de build y pruebas — 6 de octubre de 2026

## Entrega actual — ios-portrait-7-ios-mod-path

Corrige la regresión de arranque comunicada desde un iPhone real:
Lovely devuelve `/private/var/.../Documents/game/Mods/`, mientras LÖVE devuelve
`/var/.../Documents/game/Mods`. La comparación literal anterior abortaba el inicio.

`src/portrait_mods.lua` normaliza ambas rutas antes de compararlas: elimina barras
finales y aplica únicamente en iOS el alias completo `/private/var` → `/var`.
Mantiene límites de componente y mayúsculas en POSIX; la conversión de separadores
y minúsculas se limita a Windows. No contiene UUID de container ni rutas de usuario.
No se añade `realpath` mediante FFI: este código se ejecuta en `conf`, antes de
nativefs/Steamodded, y no dispone de una API portable de canonicalización. Se usa
la equivalencia específica de iOS y una comprobación adicional de acceso real.

Se crea y comprueba `Mods`; ambos mods deben existir en el paquete. El instalador
verifica todos sus archivos abriéndolos en binario desde la ruta absoluta ORIGINAL
de Lovely, conservando el alias que este devuelve. Un archivo ausente o alterado
provoca reinstalación aunque exista el sello previo. El sello de finalización se
escribe tras comprobar la copia. Destinos distintos, falta de lectura o un fallo
real de recarga de Lovely siguen produciendo un error explícito.

Validación de esta entrega:

- 202 comprobaciones del instalador con LuaJIT: caso exacto del iPhone, barras
  múltiples, límites del prefijo, UUID diferente, reinstalación, lectura denegada,
  archivos incompletos/corruptos y conservación del rechazo de destinos distintos.
- 54 fuentes Lua compilan; 7 pruebas Python pasan; 70 comprobaciones de IPA pasan,
  incluida la igualdad del instalador empaquetado con la fuente corregida.
- Tres procesos independientes con LÖVE 11.5, Lovely 0.10.0 y Steamodded real,
  perfil aislado `qa/pathfix-v7`: arranque limpio, compra y reinicio. Compound
  Interest aparece inicialmente no descubierto, se descubre al comprarlo y su
  estado persiste tras cerrar y abrir. Ambos mods cargan; 115 archivos instalados
  coinciden byte a byte con los contenidos incluidos.
- Comparación con v6: únicamente cambian `portrait_mods.lua` y la etiqueta de
  revisión en `portrait_config.lua` dentro del juego. El resto de la IPA, incluidos
  ejecutable nativo, imágenes, mods, shaders, interfaz, controles y guardados,
  mantiene exactamente los mismos contenidos.

Dos empaquetados idénticos; IPA final **79.940.450 bytes** en `../balatron.ipa`.
SHA-256: `729912764b4066190e162a47d32ddbe8b568fe72f174fd7e27755fd9baf976bc`.
Backup de la versión con la regresión: `../balatron-v6.ipa`.
Resultados: `validation-output/ipa-report-v7.json`, `pathfix-report-v7.json`,
`installer-tests-v7.txt`, `python-tests-v7.txt`; pruebas nuevas en
`tests/portrait_mods_test.lua` y `tools/collect_pathfix_qa.py`.

**Pendiente volver a probar físicamente esta corrección en el iPhone.** La prueba
de alias se ejecutó con rutas simuladas; el arranque real con ambos mods se verificó
en escritorio. Se reconoce la regresión física de v6, no se considera una mera
incidencia teórica. La nueva IPA queda preparada para firmar e instalar.

## Entrega anterior — ios-portrait-6-background-cycle

La nueva foto de Compound Interest (monedas y flecha ascendente) está integrada
en sprites RGBA 71×95 y 142×190, con marco recortado sin deformar la imagen.
Mod 1.0.2; fuente y hashes en `../MODS/Compound Interest/art-manifest.json`.
Se conserva desbloqueado, inicialmente no descubierto, visible en colección y
con probabilidad del 1 %. No se modifica su lógica de puntuación ni descubrimiento.

`portrait_background.lua` transforma exclusivamente los tres uniformes de color
de `G.SPLASH_BACK`, desde `engine/sprite.lua`. `background.fs` y `splash.fs` son
idénticos al juego original: mismas ondas, patrones, texturas, contraste y tiempos.
No se colorean cartas, HUD, textos, botones ni partículas. El ciclo de 240 segundos
usa siete tonos normalizados en luminosidad e interpolación suave y cerrada.
La configuración está en `portrait_config.lua`; `game.lua` actualiza el reloj de
color y los callbacks/UI de Graphics guardan la preferencia On/Off. Off fija verde
y conserva las ondas. La opción original Reduced Motion sigue siendo respetada.

Pruebas: 2401 fases y límites del ciclo; 7 tests Python; 67 comprobaciones del
paquete final (417 archivos). QA real de escritorio con Lovely/Steamodded y
geometría iOS: menú, selección de ciega, mano, tienda y sobre; siete tonos por
escena, primer plano idéntico píxel a píxel y regresión portrait 375×667.
La luminosidad entre tonos difiere menos de 0,0041 por cuantización de 8 bits.
El sobre naranja original recortaba canales saturados: frente a ese original
la diferencia máxima medida es 0,02874; el patrón y shader permanecen intactos.

Coste: ninguna textura, shader, pasada GPU ni envío de uniformes adicional.
Microbenchmark de escritorio de actualización y tres colores: 0,074 µs por
iteración (200.000 iteraciones); no es una medición de rendimiento en iPhone.
Logs/capturas en `qa/*background*`; validación en `validation-output/ipa-report-v6.json`.
La IPA usa el ejecutable ARM64 de la base Lovely verificada y queda preparada
para firmar. **Instalación y prueba física en iPhone pendientes.**

Dos empaquetados idénticos; IPA final: 79.939.933 bytes.
SHA-256: `2441f1e41a5b6e41a9c584510fa120af1448cb5e7a55838f8cdbc012854d3a24`.
Copia entregada: `../balatron.ipa`; anterior: `../balatron-v5.ipa`.
Dos reinicios independientes verificaron la persistencia de Off y On y que las
ondas originales cambian con el tiempo incluso manteniendo fijo el tinte nuevo.

## Entrega anterior — ios-portrait-5-compound-collection

Compound Interest **1.0.1**: `unlocked=true`, `discovered=false` y sin ocultación
de colección. Su `in_pool=false` únicamente excluye generadores aleatorios ajenos
a la tienda; no excluye `SMODS.collection_pool(G.P_CENTER_POOLS.Joker)`.
El 1 % sigue dependiendo del desbloqueo y las restricciones de oferta, no del
descubrimiento. No hay sustitución de otros Jokers ni una segunda aparición aleatoria.

La primera adquisición en una partida normal utiliza `Card:add_to_deck` →
`discover_card` → guardado nativo de `meta.jkr`. No se fuerza el descubrimiento
al iniciar ni se borra progreso previo. Se respetan las reglas normales del juego
para semillas/desafíos y los perfiles que ya lo tengan descubierto.

QA específico: tres procesos independientes del juego real de escritorio con
Lovely/Steamodded, perfil aislado `qa/discovery-v5-final`:

1. Perfil nuevo: aparece en Collection → Jokers, página 11/11, desbloqueado con
   sprite y tooltip de no descubierto. Se navega con el control normal de páginas.
2. Segundo arranque: continúa no descubierto. Oferta normal elegible a 0,009999,
   exclusión a 0,01; exponerlo en tienda no descubre. Compra con el callback normal:
   se descubre, muestra su ilustración en colección y queda registrado en el perfil.
3. Cierre completo y tercer proceso: colección descubierta desde el menú principal,
   sin cargar una partida ni volver a adquirirlo; metadatos persistentes comprobados.

7 pruebas Python correctas, 6 Lua del mod compilados y 63 comprobaciones de IPA.
Dos builds idénticas. No se repiten las pruebas extensas de gameplay v4 porque
el cambio funcional afecta solo al valor inicial de descubrimiento.
Pruebas nuevas en `tests/compound_discovery_qa.lua`; resultados y capturas en
`validation-output/compound-discovery-report.json`, `ipa-report-v5.json` y `qa/`.
**Prueba física en iPhone pendiente**; la comprobación se ha ejecutado en escritorio.

IPA: **79.932.816 bytes**; backup anterior `../balatron-v4.ipa`.
SHA-256: `5e910b00214edbdf4af4788f3594ec275b8cd6408ced297972bcfbb7c558718e`.
Game.love: `0890cc15b176f827783b89f417a0b72d328fb4bcd1ebd03f57494f00e6992381`.

Cambios: `../MODS/Compound Interest/main.lua` y `mod.json`; revisión en
`src/portrait_config.lua`; harness, validación y documentación. El mecanismo
de descubrimiento y guardado del motor permanece intacto.

## Entrega anterior — ios-portrait-4-compound-interest

IPA **79.932.739 bytes**, preparada para volver a firmar. Conserva Balatrón,
`com.rulo3.balatro.portrait`, el icono del bufón, Deck 1 y el layout anterior.
La copia anterior queda en `../balatron-v3.ipa`.

### Integración aplicada

- Mod completo en `../MODS/Compound Interest`: centro `j_incj_compound_interest`,
  SMODS.Joker y SMODS.Atlas independientes; no sustituye comodines originales.
- X1 inicial; +0,15 por ciega jugada y ganada; $10; una tirada del 1 % por oferta
  normal elegible de Joker. `settings.lua` centraliza los parámetros y `debug=false`.
- Contador y última ronda en `card.ability.extra`, con puntuación y crecimiento
  separados. No crece por copia Blueprint/Brainstorm, descarte, derrota, ciega
  saltada, tienda, recarga ni estando desactivado. Duplicaciones con estado propio.
- Sprites RGBA 71×95 y 142×190 hechos exclusivamente con la última imagen,
  recortando el exterior sin deformación. Original conservado y script reproducible.
- Steamodded **1.0.0-beta-1224a** fijado y empaquetado; Lovely **0.10.0** comprobado
  en el ejecutable iOS y ejecutado de verdad en Windows. Encontrar Lovely por sí
  solo no se tomó como prueba de que Steamodded estuviera cargado.
- Instalación temprana en `Documents/game/Mods`, recarga de parches y precarga de
  módulos para el primer arranque. Sellos SHA-256 y copia completada antes de
  escribir el sello. Detalles y cambios de compatibilidad en `mods/README.md`.
- Migración de guardados sin Steamodded, incluidos límites con negativos,
  puntuación y vales. Copia binaria original en `<perfil>/save.pre-steamodded.jkr`.
  Los guardados existentes con Steamodded no vuelven a convertirse.

### Validaciones estáticas y automatizadas

- 7 pruebas Python; 53 Lua del proyecto, 6 del mod y 29 de Steamodded compilados.
- 459 comprobaciones Lua de layout, gestos/tooltip, safe areas, skins y reglas
  del comodín; prueba adicional de migración/idempotencia del guardado.
- 62 comprobaciones de la IPA: ARM64, ejecutable original de la plantilla,
  identidad, 18 iconos, recursos originales, atlas, mod completo, parámetros de
  entrega, rutas y ausencia de hooks QA. Game.love contiene 416 archivos.
- Dos empaquetados completos consecutivos producen exactamente los mismos bytes.
- Las 11 funciones base cotejadas siguen iguales **en el código fuente incluido**.
  Steamodded aplica cambios y extensiones en ejecución; esa comprobación estática
  no equivale a afirmar que el motor resultante sea idéntico al vanilla.

### Pruebas ejecutadas en el juego

LÖVE 11.5 de escritorio con los cargadores Lovely/Steamodded reales, perfiles de
prueba aislados y las API de geometría/safe areas/DPI de iOS simuladas:

- Portrait/Deck 1: 75 registros PASS en 393×852/3x y 55 en 375×667/2x. Incluyen
  menús, selección, reordenación de dos filas, negativos, juego, tienda, compra,
  venta, reroll y cinco tipos de sobres. Sprites y tooltip inspeccionados visualmente.
- Nuevo comodín: pequeña, grande y jefe jugadas y ganadas, X1→X1,15→X1,30→X1,45;
  el callback duplicado no suma otra vez. Objetivo de las ciegas reducido solo
  en el archivo QA para poder verificar el cierre natural de la mano.
- Evaluación real de SMODS: Mult 20 × X1,30 = 26. Blueprint y Brainstorm copian
  el valor. Una duplicación real mantiene otra tabla mutable; debuff conserva
  el progreso y suprime el efecto. Compra, inspección, selección, reordenación,
  venta y oferta nueva en X1 verificadas mediante los callbacks reales.
- Hook normal de tienda: una tirada por oferta. Identidad, rareza y legendario
  forzados, tutorial y Rare Tag no invocan la tirada. Pools ajenos excluidos;
  vetos, duplicados, Showman y repetición de secuencia con semilla comprobados.
- **100.000** ofertas elegibles con la función de producción y el RNG real:
  **1.002** apariciones (**1,002 %**). Los límites 0/0,009999/0,01/0,010001 también
  se prueban; la condición es estrictamente menor que 0,01.
- Cierre de proceso y continuación: X1,45, Deck 1 y las ofertas de la tienda
  permanecen; cero tiradas del mod al cargar. Tooltip español de España muestra
  el nombre y los valores reales con coma decimal.
- Partida v3 real: conserva semilla, dinero, cartas, tienda y capacidades con
  negativos. Permite vender un negativo, reroll, seleccionar ciega, jugar,
  ganar y guardar ya en formato nuevo. Backup cotejado byte a byte con el original.

Resultados detallados: `validation-output/compound-interest-report.json`,
`ipa-report.json`, `python-tests-v4.txt`, `reproducibility.json` y capturas/logs en `qa/`.

### Pendiente en iPhone

No se ha instalado ni ejecutado físicamente esta IPA en un iPhone. Quedan por
comprobar la firma/instalación, ruta del sandbox nativo, arranque del loader ARM64,
rendimiento, audio, suspensión y controles con el dedo. Las pruebas de escritorio
no certifican esos puntos. No se han tocado credenciales de firma ni guardados del usuario.

### Archivos y hashes

Mod: `main.lua`, `logic.lua`, `settings.lua`, `lovely.toml`, `mod.json`, tres
localizaciones y dos sprites. Proyecto: `build.py`, `src/conf.lua`, `src/main.lua`,
`src/game.lua`, `src/portrait_config.lua`, nuevos `portrait_mods.lua`,
`portrait_smods.lua`, `portrait_save_migration.lua`, dependencias, herramientas,
pruebas y documentación. El diseño portrait y los controles previos se conservan.

IPA SHA-256: `6bbd95d341f998b8a9743d296d03c55f76314ab96c4620f4abd0a36d5e9941bc`.
Game.love SHA-256: `b8efeffd8740b54352150298f4968d19a434ecf2996cf931eb6de91eadee687c`.

## Nueva entrega — ios-portrait-3-deck1

IPA de **79.367.784 bytes**, con Deck 1 y todos los cambios portrait/icono anteriores.
Nombre e ID conservados: Balatrón / `com.rulo3.balatro.portrait`.
Seleccionar **Options → Customize Deck → Card Skin → Deck 1**.

- Se han releído las cinco imágenes actualizadas de `../DECK1`, no las versiones
  anteriores. Sus nombres y hashes figuran en `assets/skins/deck1/manifest.json`.
- 52 cartas más reverso, fuentes PNG RGBA de 284 × 380 y atlas 3692 × 1520,
  con celda lógica 71 × 95 a 4x. Corrección autorizada del 8 de tréboles aplicada.
- Default y colaboraciones originales conservados; elección persistente y cambio
  en caliente. Los atlas originales de Jokers, consumibles y demás familias intactos.
- 5 pruebas Python correctas: assets/mapeo, fotos actuales, ocho tréboles centrales,
  integración iOS y reproducibilidad/identidad. 112 comprobaciones Lua de skins.
- 50 Lua compilados; 219 comprobaciones de layout, 16 de gestos/tooltip y 27 de
  safe areas correctas. Las 11 funciones de gameplay cotejadas con el original siguen iguales.
- 55 comprobaciones del IPA correctas; 298 archivos en Game.love. Dos builds
  completas consecutivas idénticas. Los iconos del bufón siguen integrados.
- QA de escritorio: 72 escenarios en 393 × 852 con canvas 3x y 52 escenarios
  en 375 × 667 con canvas 2x. Cubren selector/Default, los 52 rangos, mejoras,
  mano, cartas jugadas, colección, visor, tienda, cinco tipos de sobres y negativos.
- Reinicio de proceso: Deck 1 se restaura desde settings.jkr; la partida recupera
  semilla, cartas y capacidades. Sin hooks de QA en la IPA.
- Instalación y funcionamiento físico en iPhone pendientes. La IPA se entrega
  sin firma personal, preparada para AltStore/Sideloadly.

Archivos principales: `src/card_skins.lua` (registro/carga), `src/card.lua` y
`src/functions/misc_functions.lua` (sprites), `src/game.lua`/`src/main.lua`/`src/globals.lua`
(inicialización), `src/functions/UI_definitions.lua` y `button_callbacks.lua`
(selector), assets, generador `tools/build_card_skin.py` y nuevas pruebas.
La revisión se identifica en `src/portrait_config.lua`.
Guía de regeneración y Deck 2: `assets/skins/deck1/README.md`.

SHA-256 IPA: `55773aa6cc54c6cc7ccc959428956a887998bd732cf004949eb3455556b81475`.
SHA-256 Game.love: `679df2a8d55223e40694bbca068d945ec90370bbc51e3924237a951e01984d31`.
Informes: `validation-output/ipa-report.json`, `reproducibility.json` y
`deck1-preview-report.json`. La copia entregada es `../balatron.ipa`.


## Nueva entrega — ios-portrait-2 — layout e icono del bufón

La petición posterior de cambiar el icono autoriza recompilar la IPA con todos
los cambios acumulados. El nuevo paquete incluye layout, nitidez, textos,
soporte de negativos y el icono del bufón. Conserva el nombre Balatrón,
el ID `com.rulo3.balatro.portrait` y el ejecutable nativo de la base verificada.

- Máster de 1024 × 1024 y 18 variantes de icono RGB opaco para iPhone, iPad y
  marketing; catálogo fuente y referencias reales en `Info.plist`.
- Los PNG del gato de la base se eliminan. No se conserva la referencia a su
  catálogo antiguo. Las pruebas comprueban cada tamaño y la retirada del icono.
- 49 comprobaciones del IPA correctas; 2 pruebas de empaquetado correctas,
  incluida la identidad, los iconos, los permisos y la reproducibilidad.
- Dos builds completas consecutivas producen exactamente los mismos bytes.
- Recarga adicional del `Game.love` final correcta en el banco de pruebas de
  escritorio a 393 × 852 puntos y canvas 3x, con 12 Jokers y 6 consumibles.
- Paquete preparado para firmar con AltStore/Sideloadly. Instalación, caché del
  icono y comportamiento en un iPhone físico pendientes de comprobación.

- Inventario arriba, cartas jugadas debajo, mano central y deck lateral.
- HUD inferior medido, ancho según la pantalla; acciones sobre el borde seguro.
- Mano hasta 1,42 veces el tamaño anterior y Jokers normales a 1,16. La escala
  se adapta al espacio disponible cuando hay muchos negativos.
- Más de 8 Jokers o más de 3 consumibles activan dos filas. Los huecos de
  capacidad extra no obligan a separar artificialmente las cartas existentes.
  Cada zona se adapta por separado: los comodines conservan una sola fila y su
  tamaño normal con 0–8 cartas, aunque haya muchos consumibles. Con 9 o más
  pasan a dos filas y vuelven automáticamente a una al bajar a 8.
- Tienda, ciegas y cobro se recolocan al cambiar el inventario. Los sobres
  reservan una fila propia para la mano. Contadores recalculados con cada tamaño.
- CRT atenuado en portrait sin modificar el valor guardado del deslizador;
  texturas locales 2x y DPI nativo explícito del canvas. Según la
  [documentación de LÖVE](https://love2d.org/wiki/love.graphics.newCanvas), el DPI
  del canvas es independiente de las coordenadas lógicas de la interfaz.
- 219 comprobaciones de geometría, tamaño de cartas y negativos; 16 de gestos
  y límites de tooltips; 27 de safe areas. Todos correctos.
- 49 Lua compilados y 11 funciones originales de gameplay comparadas sin cambios.
- Capturas completadas en 375×667 a 2x, 390×844 a 3x y 393×852 a 3x:
  49, 69 y 49 escenarios respectivamente. Incluyen arrastre entre filas,
  selección, 12 Jokers, 6 consumibles, tienda, cobro y los cinco tipos de sobres.
- Recarga desde un proceso nuevo correcta: misma semilla, número de cartas y
  límites de capacidad, incluido el inventario de negativos. Informes en
  `validation-output/layout-preview-report.json` y
  `validation-output/layout-core-functions.json`.

Archivos de implementación: `src/portrait_config.lua` (parámetros y geometría),
`src/functions/common_events.lua` (posiciones), `src/cardarea.lua` (tamaño,
filas y orden), `src/functions/UI_definitions.lua` (HUD y controles),
`src/game.lua`/`src/globals.lua` (anclajes y fases), `src/main.lua` (canvas),
`src/blind.lua` (ocultación del panel de ciega) y `src/card.lua` (restauración
del tamaño tras cargar). Pruebas: `tests/portrait_layout_test.lua`,
`tests/desktop_qa.lua` y `tools/desktop_qa.py`.

Las capturas de desarrollo se probaron con `tools/desktop_qa.py --source`.
La recarga final usa el `Game.love` recompilado, sin sustituir sus fuentes.
La simulación de canvas 3x comprueba 1179×2556 píxeles para un viewport
de 393×852 puntos; no equivale a una prueba física de iPhone.

### Archivo entregado — revisión 2

- Ruta: `../balatron.ipa` (copia idéntica del paquete del proyecto).
- Tamaño: 63,074,013 bytes.
- SHA-256 IPA: `dbc338b01db3f2b5391463a99db33cde811c3f02672bbc22d95a9fb27a42aa3e`.
- SHA-256 Game.love: `2b7717e4fd9bbb60e30d1f1c99a167983f991ff1adc9c163bd55435973f3e38e`.
- Informes: `validation-output/ipa-report.json`, `icon-report.json` y
  `reproducibility.json`.

## Entrega anterior — ios-portrait-1

## Resultado y límite de validación

Se ha generado `balatron.ipa` (61.356.221 bytes), preparada para firma
personal con AltStore/Sideloadly. No está firmada con una cuenta Apple ni instalada
en un iPhone. **La build y las pruebas de ordenador están verificadas; no se
certifica todavía funcionamiento completo en hardware iOS.**

Nombre: **Balatrón**. Bundle ID: `com.rulo3.balatro.portrait`.
Base: portrait 2.8.0, revisión local `ios-portrait-1`, juego 1.0.1o-FULL.
Se trabaja en `ios-portrait-production`, sobre el commit recuperado
`27bf84cdde604fe1917f5c41a5488f385ea1463d`. El origen solicitado devolvía 404;
se recuperó su historial desde el fork de beiklive, sin su cambio posterior.
No se ha publicado ningún archivo ni se ha modificado la instalación suministrada.

## Comprobaciones automáticas

| Comprobación | Resultado |
| --- | --- |
| `BUILD-IOS.ps1` y `build.py --ios --skip-apk` | Build ejecutado correctamente |
| Sintaxis Lua con el LuaJIT de la copia local | 49 archivos compilados |
| Fixtures de safe areas | 27 comprobaciones correctas |
| Gestos y límites de tooltips | 16 comprobaciones correctas |
| Tests Python de empaquetado y checksum | 2 tests correctos |
| Validación de IPA | 44 comprobaciones correctas |
| Recompilación forzada | IPA y Game.love idénticos byte a byte |
| IPA y Game.love | ZIP válidos, CRC correcto, rutas relativas, sin duplicados |
| Binario nativo | Mach-O ARM64, permisos ejecutables, sin cifrado FairPlay |
| Dependencias nativas | Solo bibliotecas/frameworks del sistema; ejecutable idéntico al shell fijado |
| Info.plist | Nombre/ID independientes, portrait exclusivo, Files habilitado, ProMotion permitido |
| Lovely | Marcadores nativos presentes; binario del shell conservado |
| Referencias | Módulos internos y recursos literales requeridos presentes |
| Datos del juego | 259 recursos/localizaciones procedentes de la copia local |
| Audio | Los 80 archivos son idénticos byte a byte a la copia local |
| Reglas | 11 funciones principales de RNG, evaluación, Jokers, sellos y consumibles idénticas al original |

Los únicos recursos locales transformados son `CRT.fs` y `flame.fs`, mediante
los parches gráficos del proyecto base. No se cambia música, balance de audio,
scoring o contenido de cartas. No se incluyen saves, Steamodded ni otros mods.
La fuente Readabletro es opcional y está ausente; el manejador de errores tiene
fallback a la fuente original. `portrait_shaders` es una dependencia opcional
exclusiva de la modalidad Zygisk y no pertenece a esta build.

Evidencia detallada: `validation-output/ipa-report.json`,
`validation-output/reproducibility.json`, `production-build.log`,
`reproducibility-build.log`, `syntax-tests.log`, `safe-area-tests.log`,
`input-tests.log` y `unit-tests.log`. La IPA descomprimida está en
`validation-output/unpacked-ipa/`.

## Ejecución y revisión visual

Se ejecutó el juego real empaquetado con LÖVE 11.5 en Windows. El arnés de QA
simula dimensiones y safe areas de iOS; **no es el simulador de Apple**.
Los perfiles de prueba se aislaron bajo `qa/appdata/`; los hooks de QA solo
existen en `qa/*/test.love`, nunca en la IPA final.

Configuraciones: 375×667 (20/0 de inset), 390×844 (47/34) y
393×852 (59/34, Dynamic Island simulada). Pasaron **45 escenarios por tamaño**;
se guardaron capturas y registros en `qa/<dimensiones>/`.

Se ejercitaron menú principal, Options, Settings, Collection, Jokers, Tarots,
Planets, Spectrals, Blinds, Tags, Vouchers, Decks, Boosters, Profiles,
estadísticas, desafíos, idioma, preparación de partida, Diagnostics paginado,
selección de ciegas, mano, Run Info, Deck, Poker Hands, 1/5/8 Jokers incluyendo
negativos, tooltip, selección múltiple, cartas con edición y sello, mano de
12 cartas, juego de una mano, tienda, compra, venta, reroll, pack, cierre de
pack y pantallas de victoria/derrota.

Las pruebas usan estados y fondos sintéticos para alcanzar escenarios sin
completar una campaña. Victory/Game Over validan construcción y renderizado de
esas pantallas; no representan una partida completa ganada o perdida. Los
gestos se comprueban con fixtures que ejecutan la función real de producción;
la ergonomía y las hitboxes bajo un dedo real siguen pendientes.

Se detectó y corrigió un error reproducible: abrir Usage/Statistics y después
iniciar una partida invalidaba la función de tipos usada por Blind Selection.
También se corrigió el panel decorativo de los packs que se prolongaba fuera
de pantalla. Las capturas se inspeccionaron para detectar recortes evidentes.

Se guardó y decodificó un checkpoint, se cerró el proceso y otra ejecución
cargó ese checkpoint conservando la seed `PORTRAIT`. Evidencia:
`qa/393x852-resume/result.txt` y `restored_run.png`.

## Retina y refresco

El código conserva `highdpi=true` para iOS tanto en `conf.lua` como al actualizar
la ventana, y `usedpiscale=true`. Se revisó el
[código oficial de LÖVE 11.5](https://github.com/love2d/love/blob/11.5/src/modules/graphics/wrap_Graphics.cpp):
`newCanvas` toma por defecto la densidad de la pantalla. Diagnostics informa
tamaño lógico, drawable físico y canvas físico para detectar una reducción real.

La sonda UIKit consulta nativeScale, scale, systemVersion y
maximumFramesPerSecond cuando están disponibles. La información se almacena y
se renueva al volver a primer plano; no se consulta cada frame. El cap automático
usa la capacidad reportada. La clave ProMotion está activada en Info.plist.
**Ni esto ni un contador de FPS prueban que el panel presente a 120 Hz.**
Los valores de 144 Hz/FPS que puedan aparecer en los logs de QA pertenecen al PC.
Las métricas UIKit muestran `?` en Windows, como corresponde.

La [documentación iOS de origen](https://github.com/ShaggyLorean/balatro-portrait-mobile/blob/main/docs/IOS.md)
y el [issue 45](https://github.com/ShaggyLorean/balatro-portrait-mobile/issues/45)
describen precisamente las limitaciones de Retina/ProMotion y validación física.

## Comprobaciones pendientes en el iPhone

1. Firmar e instalar, confirmar que aparece como aplicación separada y abre sin error.
2. Comprobar portrait al rotar, bloquear/desbloquear y volver de segundo plano.
3. Obtener Diagnostics: drawable/canvas, nativeScale, insets y Hz. Verificar
   nitidez, Dynamic Island/notch, esquinas y home indicator en el modelo concreto.
4. Probar toque, multiselección, arrastre lento y rápido, swipes intencionados,
   cancelación al bloquear, múltiples dedos y botones Jugar/Descartar.
5. Revisar tooltips largos, manos grandes, más de cinco Jokers, ediciones,
   sellos, animaciones, todos los menús y el teclado del campo Seed/Profile.
6. Completar varias rondas y una partida; comprobar audio, consumo, temperatura,
   memoria, FPS sostenidos y presentación efectiva en pantallas ProMotion.
7. Cerrar/reabrir y reinstalar una actualización sobre la misma identidad
   de aplicación/firma, conservando antes copia de `game/`. No desinstalar.
8. Si se desea Steamodded, instalarlo opcionalmente en `game/Mods/`, reiniciar y
   verificar su carga, menús, parches y guardado. No se ha ejecutado Steamodded
   en esta entrega ni se garantiza compatibilidad con cualquier mod externo.

## Integridad de la entrega

SHA-256 IPA:
`3446648c9326b89257f4b5e1d931a6d5979c44d891ccc87f43aa232ed6514b86`

SHA-256 Game.love:
`b136c0b6607752bf9e98c7d9ba3d7b2df2699a9f10ff9a39e684616861d1e801`

SHA-256 ejecutable local utilizado:
`0d75fe164accf3312734d4b37ac98788dd15f0b8e4f9bb8b7f90c4e59de93f47`

SHA-256 shell Lovely:
`14d4c378d19c6f190af163d32fdd27b34932628b5fd5a6816e8c5db578ef5fde`

## Historial del trabajo

- `fb6fff9` — identidad iOS independiente y empaquetado determinista.
- `db855ec` — tacto, safe areas, ciclo de vida, Diagnostics y correcciones de UI.
- `d10b085` — arnés aislado, validadores, pruebas y script PowerShell.
- El commit de documentación añade este informe, README local y changelog.

Se revisaron los cambios con `git diff`, `git diff --cached --check` y revisión
de lo preparado antes de cada commit. No se incluyen binarios del juego,
recursos extraídos ni datos de prueba en los commits nuevos.
