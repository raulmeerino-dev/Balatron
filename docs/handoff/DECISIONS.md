# DECISIONS — decisiones y límites documentados

La categoría «verificada» significa que la decisión está visible en el código,
README, commit o informe del repositorio; no implica que se haya vuelto a probar
en este handoff. No se encontró historial conversacional anterior recuperable.

## Arquitectura/build

| Decisión | Motivo registrado | Evidencia |
| --- | --- | --- |
| Mantener juego LÖVE/Lua y empaquetar `Game.love` en shell iOS precompilado. | Evita reimplementar reglas y permite una build Windows sin Xcode/macOS. | `balatron/build.py`, `BUILD-IOS.ps1`, `docs/IOS.md`. |
| Separar identidad iOS con `com.rulo3.balatro.portrait`. | Instalar como app separada y conservar el contenedor propio; el informe dice que no sustituye el juego oficial. | `README-IOS-LOCAL.md`, `INFORME-PRUEBAS.md`. |
| Fijar hashes/versiones de shell/mods y ordenar deterministicamente empaquetado. | Reproducibilidad y evitar que descargas mutables cambien el resultado. | `balatron/mods/README.md`, `INFORME-PRUEBAS.md`, logs. |
| Mantener fuentes definitivas de mods fuera de `balatron/` en raíz `MODS/`. | El root README explica que el builder carga `../MODS/`; conserva carpetas/proyectos y assets fuente. | `README.md`, `balatron/build.py`. |
| No generar IPA salvo solicitud exacta. | Restricción permanente solicitada para el proyecto. | Root `AGENTS.md`. |

## Interfaz e input

| Decisión | Motivo registrado | Evidencia |
| --- | --- | --- |
| Resolver layout según dimensiones/safe area, evitando offsets exclusivos de un modelo. | Adaptar varios iPhone y pantallas portrait; safe areas/inventario varían. | `src/portrait_config.lua`, `src/functions/common_events.lua`, `INFORME-PRUEBAS.md`. |
| Conservar controles Jugar/Descartar visibles por defecto; swipes son opcionales. | Mantener affordances explícitas y minimizar activaciones accidentales. | `README-IOS-LOCAL.md`, `portrait_config.lua`. |
| Swipe debe iniciar en carta seleccionada, superar umbral acumulado, rechazar hold/bloqueo y cancelarse al suspender. | Reducir falsos gestos, no convertir toque tembloroso en acción ni aceptar input de fondo. | Changelog ios-portrait-1; pruebas `portrait_input_test.lua`. |
| Mantener coordenadas lógicas de UI y usar DPI nativo para canvas. | Nitidez Retina sin convertir hitboxes a píxeles físicos. | `src/main.lua`, `conf.lua`, informe Retina/QA. |
| Tratar safe-area/ciclo iOS como datos de runtime; no fijar UUID/ruta de container. | UUID puede variar y iOS puede exponer alias de directorio. | `portrait_ios.lua`, `portrait_mods.lua`, informe ios-portrait-7. |
| No afirmar 120 Hz efectivo por el cap o por contador de FPS. | La presentación real depende del sistema y requiere hardware. | `docs/IOS.md`, `INFORME-PRUEBAS.md`. |

## Mods y contenido

| Decisión | Motivo registrado | Evidencia |
| --- | --- | --- |
| Lovely 0.10.0 y Steamodded 1.0.0-beta-1224a quedan fijados en esta build personal. | Los patrones/API probados y carga del mod no deben cambiar al recompilar. | `balatron/mods/README.md`. |
| Mods empaquetados se instalan/verifican antes del primer arranque; validar hashes/archivos, no confiar solo en sello. | Reparar instalaciones parciales y evitar un marcador que oculte datos corruptos. | `portrait_mods.lua`, informe ios-portrait-7. |
| Normalizar alias `/private/var`→`/var` solo en iOS, quitar barras finales, conservar semántica POSIX. | Corregir ruta real observada sin aceptar directorios diferentes ni cambiar mayúsculas POSIX. | Diff/changelog ios-portrait-7. |
| Guardados incompatibles se preservan; migración antigua guarda copia binaria. | No perder progreso si la migración o incompatibilidad falla. | `portrait_save_migration.lua`, `mods/README.md`. |
| Actualizar contenido de mods sin sustituir IDs/callbacks originales si se puede integrar con SMODS. | Mantener compatibilidad del juego y guardado estándar; revisión técnica requerida por cambio. | Convenciones dispersas en `MODS/` y `balatron/mods/README.md`. |

## Problemas históricos que no deben repetirse

- **No equiparar desktop QA con prueba física.** El arnés simula viewport y
  safe areas; no reemplaza iPhone. El incidente de alias de paths sí fue
  informado desde dispositivo y necesitó corrección posterior.
- **No dar por cargado Steamodded porque exista Lovely.** El informe dice que
  comprobar Lovely no prueba Steamodded; confirmar carga efectiva.
- **No asumir que una carpeta Mods ya poblada contiene la versión que acaba de
  empaquetarse.** El installer registra versión/copia y verifica contenidos.
- **No borrar un guardado incompatible ni cambiar identidad de app al actualizar.**
  Copiar `game/` y conservar bundle ID/identidad de firma antes de actualización.
- **No reemplazar shaders/fondo original al aplicar el ciclo de color.** La
  implementación registrada cambia uniforms de color y deja shaders/ondas
  originales intactos.
- **No confundir cambios de tamaño de inventario con capacidad ni colapsar orden
  de cartas.** La geometría se adapta por inventario actual y controla filas.
- **No usar tests/harnesses que reemplacen código de producción en el paquete.**
  Los hooks de QA descritos viven en `qa/*/test.love`, no en la IPA final.
- **No limpiar ni integrar copias locales para “empezar limpio”.** El checkout
  alternativo y otra copia con su propio `.git` están preservados bajo
  `local-archive/` e ignorados; mantenerlos separados salvo petición explícita.

## Alternativas y decisiones no recuperables

Los documentos sí mencionan alternativas de shell iOS (`--ios-vanilla` vs shell
Lovely), Steamodded optativo en algunas rutas Android, coordenadas codificadas
vs safe area, `realpath` FFI vs normalización específica iOS y Readabletro
opcional/omitido. No hay registro completo de experimentos conversacionales ni
de todas las opciones descartadas. No atribuir una preferencia al usuario si no
está en archivos o diff.

Discrepancias pendientes de decisión: el código actual fija fondo de 480 s y 14
paradas, mientras el informe anterior describe 240 s y siete; las etiquetas de
release aparecen como rc1/rc2/rc3 en documentos y fuente distintos. No tratar una
de ellas como decisión final sin resolver qué representa la entrega actual.
