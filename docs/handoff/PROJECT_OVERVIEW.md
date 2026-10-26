# PROJECT_OVERVIEW — Balatrón vertical para iOS

## Propósito

Este repositorio mantiene una adaptación portrait de Balatro para jugar con una
mano, con una build personal de iOS llamada **Balatrón**. El trabajo combina el
proyecto base `beiklive/balatro-portrait-mobile`, una integración iOS local,
mods/arte propios y material de diseño para mazos. El bundle iOS está separado
del Balatro oficial (`com.rulo3.balatro.portrait`).

La meta práctica no es reimplementar las reglas: se conserva el motor de Balatro
y se adapta la presentación, la interacción táctil, el contenedor iOS y contenido
adicional optativo. El estado publicado/documentado dice base 2.8.0, juego local
1.0.1o-FULL, versión del mod 2.8.1. Verificar las fuentes antes de asumir que
esos números siguen siendo los de una nueva build.

## Procedencia y certeza

- **Verificable en archivos/historial Git:** el código se publicó en `main`; el
  commit previo a esta auditoría fue `aed3f9b`, con publicación principal en
  `9ab04cb` y árbol base `2cbc19e` (16-10-2026). El repositorio contiene
  `balatron/`, README, informes y scripts. Los cambios recientes de MODS están
  confirmados en Git, aunque no revalidados en juego en esta sesión.
- **Documentado en el proyecto, no revalidado en este handoff:** resultados de
  QA y builds descritos en `balatron/INFORME-PRUEBAS.md`, `CHANGELOG.md` y
  `releases/README.md`.
- **Historial conversacional:** no se dispone aquí de conversaciones anteriores
  a la solicitud de transferencia. No se pueden recuperar acuerdos verbales,
  motivos no anotados, tareas exactas de una sesión ni alternativas que no
  aparezcan en commits, diffs o documentación. Se marcan como inferencias donde
  corresponda; no completar esos huecos inventando.

## Arquitectura y tecnologías

- **Juego:** Lua sobre LÖVE 11.x. `balatron/src/` contiene el motor/base de
  juego integrado con las adaptaciones. Es una copia/fork del proyecto de
  Balatro portrait, no una aplicación iOS nativa escrita con Swift.
- **iOS:** un shell LÖVE ARM64 precompilado con Lovely enlazado se usa como
  plantilla. `balatron/build.py` crea `Game.love`, inserta el juego y recursos
  de una copia legal local de Balatro en el `.app`, ajusta `Info.plist` y crea
  un IPA sin firmar. No requiere Xcode/macOS en el flujo documentado.
- **Parcheo/mods:** Lovely 0.10.0 carga parches; Steamodded 1.0.0-beta-1224a
  está conservado/fijado dentro de `balatron/mods/Steamodded`. Los mods propios
  están en la carpeta raíz `MODS/` y se incorporan al build.
- **Build y validación:** Python (`balatron/build.py`, scripts en
  `balatron/tools/`), PowerShell (`balatron/BUILD-IOS.ps1`), Lua/LuaJIT para
  comprobaciones del juego y Python para validadores/QA. Dependencias nativas y
  juego original no se deben reconstruir ni versionar sin necesidad.

## Adaptación portrait

El juego mantiene coordenadas lógicas de LÖVE; las funciones portrait calculan
un layout a partir del viewport, escala de sala y safe areas. `src/conf.lua`
detecta el modo vertical (`G.F_PORTRAIT`) y aplica integración de mods antes del
arranque. `src/portrait_config.lua` centraliza parámetros, escala, gestos,
targets táctiles, safe areas, Diagnostics y resolución de composición. Las
adaptaciones de zonas y UI se encuentran en `src/functions/`, `src/cardarea.lua`,
`src/game.lua`, `src/globals.lua`, `src/main.lua` y otros archivos del motor.

En una partida, el inventario de Jokers/consumibles ocupa la parte superior,
las cartas jugadas quedan debajo, la mano se amplía en la zona central, el mazo
queda a un lado y HUD/acciones se colocan abajo dentro del área segura. El espacio
es adaptable; inventarios grandes se reparten en filas. Hay controles frecuentes
de tamaño táctil, selección/arrastre y swipes opcionales para jugar/descartar.
Run Info y otras pantallas usan ancho medido y scroll vertical cuando hace falta.
Los detalles y knobs están en `balatron/README-IOS-LOCAL.md` y
`balatron/src/portrait_config.lua`.

## Mapa del repositorio

| Ruta | Función |
| --- | --- |
| `AGENTS.md` | Instrucciones permanentes para Codex/agentes. |
| `docs/handoff/` | Transferencia autosuficiente entre instancias. |
| `balatron/` | Proyecto principal de build portrait/iOS: código, build, pruebas y documentación. |
| `balatron/src/` | Código Lua del juego y adaptaciones portrait/iOS. Incluye `portrait_*.lua`, `functions/`, `engine/`, `assets/`, `expansion48/`. |
| `balatron/mods/` | Steamodded integrado y documentación de empaquetado de mods. |
| `balatron/assets/`, `balatron/src/assets/` | Arte integrado, atlas y recursos del juego/mods. |
| `balatron/art-source/` | Fuentes de arte, prompts/manifiestos y material de origen. |
| `balatron/ios/` | Máster y catálogo de iconos/documentación de integración iOS. |
| `balatron/tools/` | Validadores, generadores, harnesses y herramientas auxiliares. |
| `balatron/tests/` | Pruebas Lua/Python de regresión y QA focalizado. Hay 27 archivos de prueba observados. |
| `balatron/qa/`, `validation-output/` | Capturas, perfiles aislados e informes generados; ignorados/no fuente. No asumir que existen en otra máquina. |
| `MODS/` | Fuentes definitivas de los mods locales. `MODS/README.md` explica paquetes y propietarios; el build desde `balatron/` incorpora nueve paquetes mediante rutas relativas. |
| `DECK1/`, `DECK 2/`, `DECK 3/` | Arte fuente, iteraciones y documentos de mazos; el grado de integración es distinto por mazo. |
| `releases/` | Ubicación de entrega fuera de Git; README indica la última IPA y checksum, pero revisar disponibilidad real. |
| `builds/` | IPA locales e historial de builds; los binarios no se suben a Git. |
| `local-archive/` | Checkouts alternativos preservados localmente e ignorados por el repo principal. No son la fuente activa. |
| `Balatro/` | Copia local del juego original, ignorada y no distribuida. |

El repositorio exterior es el Git activo (`main`), `raulmeerino-dev/Balatron`.
Por petición del usuario se cambió a público en la sesión de publicación
anterior; esta auditoría no pudo volver a consultar GitHub por un error de red.
El checkout empezó en `aed3f9b`; `balatron/` es un subárbol versionado dentro del
repo, no un submódulo.

## Dependencias y requisitos

Para el flujo iOS documentado se necesita Windows/PowerShell, Python 3, una copia
legal local de Balatro compatible (la build registrada usa 1.0.1o-FULL), acceso a
los recursos locales y espacio temporal suficiente. `BUILD-IOS.ps1` resuelve
Python desde PATH o desde el runtime local de Codex, acepta `-PythonPath` y
`-GameSource`. El shell iOS reproducible se conserva en el caché de build de
`balatron/balatro-mobile-maker/` y el script valida el IPA.

Para regenerar iconos, `balatron/tools/generate_ios_icons.py` requiere Pillow;
los PNG generados ya están integrados, así que el build normal no debería exigir
Pillow. La prueba visual de escritorio usa LÖVE 11.5, Lovely y Steamodded real
en el banco descrito por el informe; esos componentes se documentan como medios
de QA, no como precondición probada de la build estándar. La carpeta de
herramientas y logs locales puede no estar disponible en un checkout limpio.

### Build conocida (no ejecutar sin petición expresa)

Desde raíz del proyecto:

```powershell
cd balatron
.\BUILD-IOS.ps1 -GameSource 'C:\ruta\Balatro\Balatro.exe'
```

Equivalente registrado: `python build.py --ios --skip-apk --keep-crt
--no-readabletro --force --balatro "../Balatro/Balatro.exe"`, seguido por
`python tools/validate_ipa.py --original ...`. Genera/modifica archivos binarios;
la instrucción permanente actual prohíbe hacerlo salvo solicitud textual
«Genera la IPA».
