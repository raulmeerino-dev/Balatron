# Informe de build y pruebas — 6 de octubre de 2026

## Resultado y límite de validación

Se ha generado `balatro-portrait.ipa` (61.356.221 bytes), preparada para firma
personal con AltStore/Sideloadly. No está firmada con una cuenta Apple ni instalada
en un iPhone. **La build y las pruebas de ordenador están verificadas; no se
certifica todavía funcionamiento completo en hardware iOS.**

Nombre: **Balatro Portrait**. Bundle ID: `com.rulo3.balatro.portrait`.
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
