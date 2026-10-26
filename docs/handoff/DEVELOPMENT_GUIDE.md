# DEVELOPMENT_GUIDE — continuar el proyecto

## Antes de editar

1. Leer raíz `AGENTS.md` y este directorio `docs/handoff/`.
2. Ejecutar `git status --short`; los cambios recientes en `MODS/` están
   confirmados en `9ab04cb` pero siguen sin validación de juego. Preservar el
   checkout alternativo de `local-archive/alternate-checkouts/` y no integrarlo
   salvo que el usuario lo pida.
3. Para cambios de mods, leer también `MODS/README.md` y
   `docs/handoff/MOD_CATALOG.md`. Leer documentación específica:
   `balatron/README-IOS-LOCAL.md`,
   `INFORME-PRUEBAS.md`, `CHANGELOG.md`, `mods/README.md` o README del mod.
4. Determinar cuál archivo es fuente definitiva. Para los mods locales, raíz
   `MODS/` es el origen que empaqueta el build; no editar solo un artefacto
   copiado en otra carpeta.

## Preparación del entorno

Para la build iOS documentada: Windows con PowerShell, Python 3, copia legal
local compatible de Balatro (registrada: 1.0.1o-FULL) y archivos locales de shell
de build. El wrapper busca `python` en PATH y, si no, en el runtime local de
Codex; permite `-PythonPath`. `-GameSource` selecciona explícitamente
`Balatro.exe`. Evitar descargar/reemplazar herramientas si ya existe un shell
cacheado y verificado.

La build normal no necesita Pillow si solo usa iconos ya generados. El generador
de variantes sí requiere Pillow. Los tests de Lua pueden requerir LuaJIT/runtime
local; la QA visual de escritorio histórica depende de LÖVE 11.5, Lovely y
Steamodded integrados. Ver `balatron/tools/` y logs para comandos exactos. No
inventar que Android/Termux está soportado por el build personal iOS: hay
`termux-build.sh` en la base upstream, pero el alcance actual es Balatrón iOS.

## Comandos conocidos

### Build iOS — prohibida sin petición expresa

```powershell
cd balatron
.\BUILD-IOS.ps1 -GameSource 'C:\ruta\Balatro\Balatro.exe'
```

El wrapper corre `build.py --ios --skip-apk --keep-crt --no-readabletro --force`
y `tools/validate_ipa.py --original`. Este comando genera/modifica IPA; no
ejecutarlo salvo que el usuario diga explícitamente «Genera la IPA».

### Comprobaciones acotadas

Los comandos disponibles incluyen `python tools/validate_ipa.py` (valida el IPA,
requiere IPA presente), pruebas Python de empaquetado, y scripts Lua de
`tests/`. Los logs existentes en `balatron/*-tests.log` documentan ejecuciones
anteriores. Revisar la ayuda/encabezado de cada script antes de invocarlo. Por
instrucción del proyecto, limitarse a sintaxis, referencias, rutas, assets e
integración evidente; no ejecutar suites largas ni añadir herramientas sin
petición.

Para sintaxis Lua, usar el LuaJIT disponible/local según scripts existentes; no
asumir que `luac` está en PATH. Desde `balatron/`, la auditoría del 26-10-2026
comprobó todos los Lua de los mods con:

```powershell
python tools/lua_check.py ../MODS
```

También pasaron los checks existentes de assets `tests/test_card_skin_assets.py`
y `tests/test_compound_interest_assets.py`; este último requiere
`$env:PYTHONPATH='.'` en PowerShell para que encuentre `tools`. Son verificaciones
de sintaxis/assets/paquete, no una partida, validación de guardados ni prueba en
iPhone. Para cambios nuevos, basta la comprobación focalizada de archivos tocados
cuando sea posible.

## Organización y convenciones observadas

- Lua en archivos pequeños por responsabilidad; mods suelen tener `main.lua`,
  `config.lua`, lógica/UI separada, `localization/` en `en-us.lua`, `es_419.lua`,
  `es_ES.lua`.
- El proyecto tiene `.luacheckrc`, pero la guía del usuario prioriza sintaxis,
  referencias e integración, no una suite amplia.
- `PORTRAIT_CONFIG` concentra tuning del layout y va versionado con el mod.
  Algunos campos son legacy: los comentarios del archivo dicen que
  `hud_top_space`, `card_scale`, `jokers_y` no controlan el layout nuevo.
- Mantener condicional portrait para UI específica; no romper desktop.
- Mantener saves backward-compatible. Para instalaciones/mods, asegurar
  operaciones idempotentes, comprobación de archivos y no marcar instalación
  completa antes de validar la copia.
- Assets finales se editan en su ubicación fuente definitiva. Consultar README,
  manifests y guías de `DECK 2/`, `DECK 3/` y `balatron/assets/skins/` antes de
  cambiar arte o atlases.

## Componentes delicados

- `balatron/src/conf.lua`: orden temprano de config y mods, previo a módulos
  normales. No usar APIs que todavía no existen en esta fase.
- `balatron/src/portrait_mods.lua`: normalización de rutas iOS, install path y
  verificación/copia de mods.
- `portrait_config.lua`: geometría y hooks Steamodded; revisar comentarios y
  distinguir knobs actuales de campos legacy.
- `src/cardarea.lua`, `card.lua`, `functions/common_events.lua`, `game.lua`,
  `globals.lua`, `functions/UI_definitions.lua`, `main.lua`: composición, orden,
  hitboxes, guardado, tamaños/canvas.
- `portrait_save_migration.lua`: copia y migración de datos de usuario.
- `build.py`, `BUILD-IOS.ps1`, `tools/validate_ipa.py`: pueden crear o borrar
  salidas de build, extraer recursos o modificar paquetes; revisar efectos antes.
- Fuentes bajo `MODS/`: modificación de gameplay; verificar RNG, callbacks,
  traducciones y estado persistente. No editar solo un duplicado de build.

## No hacer

- No generar/recompilar IPA sin la frase exacta «Genera la IPA».
- No limpiar/revertir cambios preexistentes ni borrar o integrar el material de
  `local-archive/` sin petición explícita.
- No reportar que una simulación de viewport demuestra compatibilidad física.
- No incluir passwords, certificados, tokens, saves personales o datos del
  usuario en documentación/commits.
- No añadir suites largas, benchmarks, debug tools o informes extensos si no lo
  pide el usuario.
