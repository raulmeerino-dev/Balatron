# CURRENT_STATE — estado al preparar el handoff

## Fuente de estado

Este resumen refleja el árbol inspeccionado el 26-10-2026 y la publicación en
GitHub de ese día. No se ejecutó build, suite ni prueba de juego. Se leyeron
estado/diffs de Git, se revisó el staging y se verificó por API la privacidad, el
HEAD remoto y la presencia del catálogo. Los informes de juego son evidencia
histórica, no una revalidación ejecutada durante esta transferencia.

## Rama, commit y cambios locales

- Rama: `main`; HEAD publicado `9ab04cb` (`docs(handoff): prepare private
  GitHub transfer`). El padre inmediato es `2cbc19e` (`docs(project): preserve
  deck artwork, checks and local delivery guide`, 16-10-2026).
- En el momento de la comprobación posterior al push, `git status --short` no
  mostró cambios locales. Los 11 diffs de `MODS/` descritos abajo se incluyeron
  en `9ab04cb`; no se compilaron ni validaron en juego como parte de la subida.
- Remoto: `origin` → `https://github.com/raulmeerino-dev/Balatron.git`.
  Repositorio verificado como **privado**. `main` remoto y HEAD local coincidían
  en `9ab04cbd2bab9791cb06fd349bf11d377b7547be`; el archivo
  `docs/handoff/MOD_CATALOG.md` se comprobó presente en GitHub. La CLI quedó
  autenticada como `raulmeerino-dev`.
- También existe `balatro-portrait-mobile-codex-test-20261017/`, otro checkout
  Git en el mismo HEAD `2cbc19e`. El usuario decidió conservarlo aparte y
  excluirlo del repo principal. Se añadió a `.gitignore`; no borrarlo ni
  migrarlo. Contiene diffs posteriores (17 archivos, 248 inserciones y 79
  eliminaciones), recursos/builds locales ignorados y dos IPA. La mayoría de sus
  cambios de MODS coinciden byte a byte con los del checkout principal; difiere
  `MODS/Events/black_market/consumable_ui.lua`, que contiene una interfaz de
  selección/confirmación más extensa. También modifica `MODS/Horizons/packs.lua`,
  `balatron/src/engine/ui.lua`, `balatron/src/portrait_config.lua`,
  `balatron/src/portrait_popup_layout.lua` y dos QA fixtures. No se integraron al
  checkout principal porque el usuario pidió mantenerlo separado.
- Las diez IPA que estaban sueltas en la raíz se ordenaron bajo
  `builds/archive/root-ipa-history/`, conservando sus nombres. Siguen excluidas
  por `.gitignore`; no se generó ni recompiló ninguna.
- Se generó este handoff en `docs/handoff/`, se amplió `AGENTS.md` y se ajustaron
  `README.md`, `.gitignore` y `builds/README.md` para documentar la publicación
  privada y la exclusión de artefactos.

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
el contenido ignorado completo de `Balatro/`, `BALATRON-ORGANIZADO/`, `builds/` y
`portrait/`, ni se ejecutó un build en esta sesión.
