# Balatrón · iOS portrait

Repositorio personal de la adaptación vertical de Balatro, con mods locales,
assets y herramientas de compilación. La versión actual incluye la corrección
responsive de Run Info para el viewport del iPhone 14 Pro.

## Organización

| Carpeta | Contenido |
| --- | --- |
| [`balatron/`](balatron/) | Proyecto principal, código Lua, assets integrados y scripts de build. |
| [`MODS/`](MODS/) | Fuentes y assets de los mods locales que incorpora el build. |
| [`DECK1/`](DECK1/) | Arte fuente del primer mazo. |
| [`DECK 2/`](DECK%202/) | Arte y trabajo del segundo mazo. |
| [`DECK 3/`](DECK%203/) | Arte y trabajo del tercer mazo. |
| `builds/` | IPA locales e historial de builds; los binarios se excluyen de Git. |
| `releases/` | Notas y checksum de la entrega registrada. |

Las carpetas mantienen sus rutas originales: `balatron/build.py` carga los mods
desde `../MODS/`. Los sprites y atlas integrados están en `balatron/assets/`,
`balatron/src/assets/` y los directorios `assets/` de cada mod; las ilustraciones
fuente y variantes se conservan junto a sus proyectos.

## Compilar para iOS

Necesitas Python 3 y una copia local de Balatro. Desde PowerShell:

```powershell
cd balatron
.\BUILD-IOS.ps1 -GameSource 'C:\ruta\Balatro\Balatro.exe'
```

El script genera `balatron/balatron.ipa` y valida su contenido. La instalación
original, los recursos extraídos, herramientas descargadas, cachés y partidas
de QA no se versionan. El historial de IPA antiguas permanece local.

Las IPA históricas se conservan localmente bajo `builds/`; no se suben al
repositorio. Puedes adjuntar una IPA a una Release de GitHub por separado cuando
decidas distribuir una versión. No se recompila una IPA sin petición explícita.

## Documentación

- [Build, instalación y guardado en iOS](balatron/README-IOS-LOCAL.md).
- [Cambios acumulados](balatron/CHANGELOG.md).
- [Validaciones y limitaciones de las pruebas](balatron/INFORME-PRUEBAS.md).
- [Integración de mods](balatron/mods/README.md).
- [Instrucciones de trabajo](AGENTS.md).

Run Info conserva sus pestañas y mecánicas. Su ancho se obtiene del viewport y
la safe area; el contenido usa scroll vertical cuando lo necesita. Se revisaron
Poker Hands, Blinds, Vouchers y Run en ES/EN con LÖVE, Lovely y Steamodded en
escritorio, emulando 393 × 852 e insets de iPhone 14 Pro. La validación física
en iOS sigue pendiente.

## Procedencia

El proyecto parte de `beiklive/balatro-portrait-mobile`. Se conserva el historial
local previo y la [licencia del proyecto base](balatron/LICENSE). Los mods y
dependencias conservan sus propios avisos y licencias. Véase también la
[documentación original](balatron/README.md).
