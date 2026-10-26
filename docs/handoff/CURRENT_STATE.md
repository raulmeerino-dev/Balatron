# CURRENT_STATE — estado del proyecto y publicación

## Fuente de estado

Este resumen registra las auditorías estáticas de mods y gráficos del
26-10-2026. La auditoría de mods comenzó en `aed3f9b` y se publicó en `90534ec`;
la auditoría gráfica comenzó desde el estado posterior `ed05079`. No se ejecutó
build, suite ni partida. Los informes de juego son evidencia histórica, no una
revalidación ejecutada durante estas auditorías.

## Rama, commit y cambios locales

- Rama: `main`; la auditoría comenzó en `aed3f9b` (HEAD y `origin/main`
  coincidían) y sus cambios se guardaron en `90534ec` (`docs(mods): audit package
  organization and dependencies`). `9ab04cb` contiene la publicación principal;
  el árbol de código previo llega a `2cbc19e` (16-10-2026).
- El checkout estaba limpio antes de esta auditoría. Los cambios de mods ya
  están en `9ab04cb`; no se compilaron ni validaron en juego durante esta tarea.
- Remoto: `origin` → `https://github.com/raulmeerino-dev/Balatron.git`.
  Tras la petición explícita del usuario, el estado **público** se verificó en
  la sesión de publicación anterior. No se pudo repetir la consulta de GitHub
  API durante esta auditoría porque `gh` reportó un error de conexión a
  `api.github.com`; confirmar al recuperar conexión. El remoto local apunta a
  `https://github.com/raulmeerino-dev/Balatron.git`.
- `local-archive/alternate-checkouts/balatro-portrait-mobile-codex-test-20261017/`
  es otro checkout Git en el mismo HEAD `2cbc19e`. El usuario decidió conservarlo
  aparte y excluirlo del repo principal. Se movió intacto bajo `local-archive/`,
  ignorado por Git; no borrarlo ni integrarlo. Contiene diffs posteriores (17
  archivos, 248 inserciones y 79 eliminaciones), recursos/builds locales
  ignorados y dos IPA. El checkout ocupa 4.13 GB (17.637 archivos medidos). La
  mayoría de sus cambios de MODS coinciden byte a byte con los del checkout
  principal; difiere
  `MODS/Events/black_market/consumable_ui.lua`, que contiene una interfaz de
  selección/confirmación más extensa. También modifica `MODS/Horizons/packs.lua`,
  `balatron/src/engine/ui.lua`, `balatron/src/portrait_config.lua`,
  `balatron/src/portrait_popup_layout.lua` y dos QA fixtures. No se integraron al
  checkout principal porque el usuario pidió mantenerlo separado. El movimiento
  conservó su estructura interna y sus rutas relativas.
- `BALATRON-ORGANIZADO/` se movió intacto a
  `local-archive/alternate-checkouts/BALATRON-ORGANIZADO/`; conserva su `.git`,
  cambios locales en README/releases y unos 4.845 archivos (3,14 GB).
- `portrait/` solo contenía un `.git` de 18 archivos, con HEAD en
  `refs/heads/.invalid` y sin archivos de trabajo. Se preservó en
  `local-archive/upstream/portrait-empty-checkout/`.
- `local-archive/` está ignorado desde la raíz. Las tres carpetas quedan fuera de
  GitHub; `local-archive/README.md` documenta su propósito solo en este equipo.
  El resumen de estas copias también está en este archivo, que sí está versionado.
- Las diez IPA que estaban sueltas en la raíz se ordenaron bajo
  `builds/archive/root-ipa-history/`, conservando sus nombres. Siguen excluidas
  por `.gitignore`; no se generó ni recompiló ninguna.
- Dos IPA con nombres de test/stable-backup que estaban directamente en
  `builds/` se movieron a `builds/archive/alternate-checkout-20261017/`; siguen
  ignoradas y se conservan también junto a su checkout alternativo.
- Se añadió `builds/README.md` y un mapa local en `local-archive/README.md` para
  distinguir fuente activa, builds ignoradas y checkouts históricos.
- Se generó este handoff en `docs/handoff/`, se amplió `AGENTS.md` y se ajustaron
  `README.md`, `.gitignore` y `builds/README.md` para documentar la publicación
  y la exclusión de artefactos.

## Auditoría de mods (26-10-2026)

- Se confirmó la separación física/técnica/conceptual de nueve paquetes en
  `balatron/build.py::_bundled_mods()` y sus `mod.json`. Se creó `MODS/README.md`
  como mapa operativo y se amplió `docs/handoff/MOD_CATALOG.md`.
- **Problema confirmado y corregido:** `MODS/Events/` llama directamente a
  Gameplay Core (`PortraitGameplay` desde la UI de consumibles y al cargar
  Expansion48), pero `MODS/Events/mod.json` solo declaraba Steamodded. Ahora
  declara también `portrait_gameplay (>=1.0.0)`. El análisis estático encontró
  nueve IDs de paquete únicos y ninguna dependencia no resuelta.
- `Gameplay Core` registra `p_pg_roulette`; no es solo infraestructura.
- `Compound Interest` ya tiene nombre visible de paquete `Extra Jokers`. Se
  conservaron carpeta `Compound Interest/`, ID `incremental_joker`, prefijo
  `incj`, Joker `j_incj_compound_interest`, configuración Doubles y estructura
  de progreso. No hizo falta renombrar objetos.
- `MODS/Black Market/` es arte conceptual sin `mod.json`; el contenido ejecutable
  Black Market/Dealer/Contraband es propiedad de `Events`.
- **Riesgo no confirmado:** varios mods encadenan wrappers de `create_toggle`; el
  load-order podría volver frágil esa composición. No se reprodujo un fallo y no
  se refactorizó. Los accesos opcionales Events→RunRules/Risk/UPG/Fusion
  observados están protegidos en el código revisado.
- Comprobaciones focalizadas: JSON válido en nueve manifiestos, IDs únicos,
  dependencias resolubles y `git diff --check`. No se ejecutó Lua, juego, suite,
  build ni prueba física. La consulta `gh repo view` falló por conectividad, pero
  `git push origin main` confirmó el fast-forward de `aed3f9b` a `90534ec`.

## Auditoría gráfica (26-10-2026)

- El informe detallado es `docs/handoff/GRAPHICS_AUDIT.md`; se añadió también a
  `AGENTS.md` y al README. Se inventariaron recursos runtime, arte fuente,
  `card_skins.lua`, el sistema Atlas de Steamodded y el empaquetado de `build.py`.
- Se confirmó que `MODS/Contracts/art-source/expansion/` y
  `MODS/Joker Fusion/art-source/` no contienen rutas de sprite runtime. Sus
  referencias estaban en manifests/prompts excluidos por el builder; los
  registros usan las imágenes bajo `assets/{1x,2x}`. `build.py` ahora excluye
  ambas carpetas de arte fuente sin borrar los originales.
- Ahorro medido al quitar esas entradas del `Game.love` existente en una
  simulación ZIP en memoria: 12.048.500 bytes (11,490 MiB); la estimación para la
  entrada comprimida dentro de IPA es 12.051.094 bytes (11,493 MiB). La IPA
  existente no se modificó: el ahorro solo llegará a una build futura.
- No hay escalas 4x dentro de MODS; los pares 1x/2x (220 atlas por escala) y los
  68 pares base duplican dimensiones exactamente. Deck 1 usa dpi=4; las cinco
  skins parciales usan 2x.
- A escala 2, la estimación corregida de texturas residentes es ~289,246 MiB con
  mipmaps completos bajo RGBA8: se cuentan 65 texturas base a 2x y los dos logos
  cargados siempre a 1x, más mods y skins. `balatro_alt.png` se conserva pero no
  tiene referencia textual encontrada. No es una medición GPU.
  `CardSkins.load_atlases()` carga todas las skins, no solo la seleccionada.
  Steamodded también conserva `ImageData` junto a `Image`; las posibles
  optimizaciones de vida útil de texturas requieren pruebas de
  compatibilidad/runtime y no se aplicaron.
- El `.ipa` y `Game.love` locales se inspeccionaron en solo lectura. No se generó
  ni recompiló IPA; no se realizó perfil de memoria en iPhone. El cambio del
  builder y el informe gráfico se publicaron en `origin/main`, commit `bd11fc8`.

## Auditoría general de mods (26-10-2026)

- Se leyó `AGENTS.md`, el handoff disponible, `MODS/README.md` y
  `balatron/mods/README.md` antes de continuar la revisión. Se contrastaron los
  nueve manifiestos activos, entrypoints, IDs, dependencias declaradas, módulos
  Gameplay Core/Expansion48 y el catálogo de contenido.
- Comprobación estática: nueve IDs únicos y todos los `main.lua` declarados
  existen; las dependencias declaradas resuelven a los paquetes incluidos o a
  Steamodded. Los 137 archivos Lua de `MODS/` compilan con el LuaJIT local.
- Las pruebas focalizadas `tests/test_card_skin_assets.py` (3 casos) y
  `tests/test_compound_interest_assets.py` (2 casos) pasaron. La prueba de
  Compound se ejecutó con `PYTHONPATH=.` desde `balatron/`, como requiere su
  import de `tools`.
- No se encontró otro error estático confirmado que justificara mover registros,
  alterar propietarios, renombrar IDs o tocar progreso. La dependencia directa
  Events → Gameplay Core ya se había corregido en la auditoría de mods publicada
  (`MODS/Events/mod.json`). No se alteraron mecánicas, RNG, probabilidades,
  desbloqueos ni formatos de guardado en esta revisión.
- Esto no acredita carga real en Steamodded ni compatibilidad de una partida. La
  UI/guardado de Marked Card, los cambios de notificación de Horizons y otros
  cambios recientes siguen pendientes de verificación en juego; véase
  `NEXT_STEPS.md`.

### Qué parecen estar haciendo los diffs (inferencia por código, no por chat)

- `MODS/Events/black_market/contraband.lua`, `contraband/marked_card.lua`,
  `consumable_ui.lua` y localizaciones: «Marked Card» prepara resultados
  aleatorios de enhancement/sello, los conserva en `card.ability.cb_choices`,
  los presenta en el preview y aplica esos resultados al objetivo al usarlo.
  La localización describe que la edición se conserva. Incluye checkpoint de
  elección y nuevo parámetro `choice` al callback `apply`.
- `MODS/Horizons/ui.lua`: cambiar el aviso de desbloqueo genérico por caja de
  desbloqueo con título por categoría, icono y texto de misión.
- `MODS/Compound Interest/options.lua`, `precision_jokers.lua`,
  `MODS/Deck Mutations/notifications.lua` y `unlocks.lua`: cambios de opciones,
  precisión y avisos/desbloqueos. Revisar el diff para entender intención antes
  de continuar; no hay requisito conversacional recuperable.
- Estos cambios de `MODS/` se publicaron en el commit, pero no se incorporaron a
  una build verificada durante esta sesión. No se debe usar una IPA existente
  como evidencia de que los contiene.

## Funcionalidad implementada y verificada según registros

**Los puntos siguientes están descritos en informes/changelog; no se volvieron a
probar ahora.** El informe principal es `balatron/INFORME-PRUEBAS.md`.

- Layout portrait adaptable, safe areas dinámicas, controles táctiles y swipes
  con límites/cancelación; Diagnostics paginado y mediciones iOS cuando están
  disponibles.
- Menús y pantallas ajustadas a portrait, HUD, inventario multi-fila, cartas,
  tooltips, Run Info, opciones, colecciones y pantallas de partida según la QA
  de escritorio descrita.
- Steamodded y Lovely integrados con instalador/mod path iOS. La corrección
  documentada para `/private/var` frente a `/var` fue probada con rutas
  simuladas y en escritorio, no de nuevo en iPhone.
- Deck 1, icono iOS y mods locales (Compound Interest, Events, Horizons, etc.)
  integrados en la build registrada. `balatron/README-IOS-LOCAL.md` y
  `balatron/mods/README.md` detallan restricciones.
- Build reproducible, validación de IPA y varias comprobaciones estáticas/QA de
  escritorio aparecen en logs e informes históricos.

## Parcial / no validado

- **Uso físico en iPhone/iPad:** firma, instalación, safe area real, navegación
  de ciclo de vida, toque/arrastre, respuesta háptica, rendimiento, refresco
  efectivo y persistencia en hardware siguen pendientes según los documentos.
- **Decks 2 y 3:** assets de diseño existen, pero README local declara que siguen
  como trabajo pendiente; no están demostrados como opciones integradas.
- **Cambios recientes de mods ahora confirmados:** estado y compatibilidad de
  guardado/preview de «Marked Card», UI de Horizons y cambios vecinos no están
  comprobados en juego.
- **Build actual desde HEAD:** no se sabe si reproduce exactamente la última IPA.
  La carpeta `releases/README.md` habla de una IPA del 16-10 con
  83 comprobaciones, pero el binario/checksum deben verificarse en el checkout.
- **Revisiones/documentación no sincronizadas:** `balatron/README-IOS-LOCAL.md`
  anuncia `ios-portrait-rc2-ui`; `balatron/src/portrait_config.lua` tiene
  `ios-portrait-rc3-ui-lifecycle`. El changelog abre con RC1 y el root README
  describe una actualización de Run Info. `version = "2.8.1"` sí coincide en el
  código/documento principal. Averiguar qué etiqueta corresponde a la entrega
  actual antes de actualizar una IPA o presentar una release.
- **Parámetros de fondo:** `portrait_config.lua` registra 480 segundos/14 paradas;
  documentación histórica de ios-portrait-6 dice ciclo de 240 segundos/siete
  tonos. Puede ser una iteración posterior o documentación obsoleta; no cambiar
  el comportamiento sin confirmar qué estado se considera intencional.
- **120 Hz/ProMotion:** el código intenta adaptarse a capacidad reportada; esto
  no prueba que iOS presente a esa frecuencia. No afirmar soporte verificado.

## Pendiente general conocido

1. Completar pruebas en dispositivo iOS real, empezando por arranque limpio y
   safe areas/ciclo de vida, luego interacciones, guardado y sesión larga.
2. Revisar y concluir los cambios recientes de `MODS/`; comparar con cambios de la
   carpeta test solo si el usuario revoca la instrucción de mantenerla aparte.
3. Mantener comprobación de integración en fuentes: sintaxis, rutas, assets,
   staging desde `MODS/` y referencias. No hacer una build IPA salvo petición.
4. Diseñar e integrar Deck 2/3 solo si el usuario decide retomar esos proyectos.

## Información que no se pudo recuperar

No hay acceso a conversaciones anteriores ni a notas de sesión no guardadas en
archivos. No se puede afirmar el motivo de cada cambio sin confirmar, prioridades
acordadas fuera del repo o qué pruebas manuales ejecutó el usuario. No se verificó
el contenido ignorado completo de `Balatro/`, `builds/` o recursos generados bajo
`local-archive/`, ni se ejecutó un build en esta sesión.
