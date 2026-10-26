# Auditoría de recursos gráficos

Fecha: 26-10-2026. Auditoría estática de fuentes, manifiestos, código de carga,
builder y artefactos locales existentes. No se recompiló ni modificó `Game.love`
o la IPA. Las cifras de memoria son estimaciones, no mediciones de Instruments.

## Resumen de resultados

- El juego base usa atlas PNG en `balatron/src/resources/textures/{1x,2x}`;
  selecciona la escala 1 o 2. Los nueve mods incluidos usan PNG en
  `assets/{1x,2x}` y Steamodded abre la escala seleccionada.
- Los 68 PNG de cada escala base tienen pareja 1x/2x con dimensiones exactas al doble.
  Los mods activos tienen 220 archivos por escala, mismos nombres relativos y
  dimensiones 2x exactamente dobles. No hay `assets/4x` en los mods.
- Deck 1 es una excepción deliberada: `CardSkins` fija `dpi=4` y usa atlases de
  4x. Las cinco skins parciales tienen diez atlases 2x. Actualmente se cargan
  todos los atlases custom al preparar render, aunque la skin activa sea Default.
- Se comprobó que el paquete de iOS existente incluía doce imágenes de concepto
  no utilizadas por registros runtime: once de Contracts y una de Joker Fusion.
  `build.py` ahora excluye esos dos directorios `art-source` al preparar los
  paquetes. Los originales, atlas, registros y ubicaciones de sprite se conservan.
- Al simular en memoria el filtrado sobre el `Game.love` que ya existe, el archivo
  interno bajaría **12.048.500 bytes (11,490 MiB)**; la compresión externa ZIP de
  `Game.love` dentro de IPA bajaría aproximadamente **12.051.094 bytes
  (11,493 MiB)**. Es ahorro proyectado para una futura build: el artefacto actual
  no cambia y no se generó IPA.
- Estimación RGBA8 de texturas residentes a escala 2: **289,246 MiB con cadena
  mip completa** si todas las atlas registradas permanecen cargadas. El cálculo no incluye
  framebuffers, canvas del juego, shaders, texturas del sistema ni overhead del
  driver. No se midió memoria real en iOS.

## Cómo se carga y empaqueta

### Juego base

`balatron/src/game.lua` crea la lista de atlas con
`resources/textures/..texture_scaling..x/`. El valor inicial es 2; el ajuste de
gráficos conmuta entre 1 y 2. Hay 68 PNG por escala (20 archivos en la raíz y 48
de colaboraciones), pero el runtime carga 65 texturas de la escala elegida y fija
los dos logos (`playstack-logo.png`, `localthunk-logo.png`) desde 1x. El archivo
`balatro_alt.png` está en ambos directorios, sin referencia textual encontrada
en el código del juego/mods; se conserva por compatibilidad potencial con mods
externos y no se cuenta como textura residente. Las texturas activas se cargan como
`love.graphics.newImage(..., {mipmaps=true, dpiscale=texture_scaling})` para los
atlas principales. `G.ASSET_ATLAS.Planet` y `.Spectral` apuntan al mismo
objeto Tarot: esos nombres son alias, no copias de textura.

### Mods

`balatron/mods/Steamodded/src/game_object.lua`, en `SMODS.Atlas.inject`, construye
la ruta `mod.path .. 'assets/' .. texture_scaling .. 'x/' .. path`, crea un
`ImageData` y una `Image` de LÖVE con `mipmaps=true`. `disable_mipmap` evita
seleccionar el filtro mipmap para ese atlas, pero la llamada de creación sigue
solicitando mipmaps. Algunos mods fijan nearest para pixel art; otros usan
linear. No cambiar flags de registro ni filtros sin comprobar su presentación.

El mismo código guarda `self.image_data` en el objeto Atlas después de crear la
Image; no se encontró una liberación posterior en Steamodded ni otro uso de esa
propiedad en el código local. Eso mantiene una copia CPU decodificada mientras
el objeto siga vivo. No se liberó: puede ser parte de compatibilidad de la API de
mods externos.

`balatron/build.py::_bundled_mods()` copia los nueve paquetes seleccionados por
el builder a `install_mods/` dentro de `Game.love`; `build_game_love()` escribe
el archivo con `ZIP_DEFLATED`. La IPA guarda `Game.love` como entrada ZIP, ya
comprimida internamente, así que una reducción del `.love` se refleja casi
íntegra en el tamaño de IPA. No se ejecutó el build en esta auditoría.

### CardSkins

`balatron/src/card_skins.lua` conserva las celdas lógicas de 71×95. Deck 1 usa
`assets/skins/deck1/` con `dpi=4`: `fronts.png` y `enhanced.png` son 3692×1520;
`back.png` es 284×380. Al cargar Deck 1 se crean cuatro texturas finales:
fronts, enhanced, back y wild; wild vuelve a leer enhanced y aplica el shader.
Los PNG originales de Deck 1 se liberan tras copiarse a canvas. Es una copia de
textura intencional para la representación wild, no un archivo duplicado.

`four_realms`, `four_realms_v2`, `velvet_catastrophe`, `dream_circuit` y
`carnival_relics` son skins parciales. Cada una aporta `fronts_lc.png` y
`fronts_hc.png` a 1846×760 (`dpi=2`); `newImage` usa `mipmaps=false` y nearest.
Estas capas reutilizan los atlas nativos para papel, mejoras y estructura de
cartas. `CardSkins.load_atlases()` recorre todos los registros, no solo el
seleccionado.

## Tamaños: archivos fuente, bundle y salida existente

Un MiB son 1.048.576 bytes. Las cifras de `MODS/` incluyen PNG/JPEG fuente, no
solo imágenes de runtime. `1x` y `2x` son los bytes de disco de sus carpetas
respectivas. “Otros” son imágenes fuera de esas dos rutas, normalmente arte
fuente/conceptual que el builder filtra.

| Paquete | Gráficos en fuente (n.º / MiB) | `assets/1x` MiB | `assets/2x` MiB | Otros MiB | Atlas 1x+2x; ZIP PNG en `Game.love` después del filtro |
| --- | ---: | ---: | ---: | ---: | --- |
| Compound Interest / Extra Jokers | 101 / 34,963 | 0,373 | 0,520 | 34,070 | 37 + 37; 0,892 MiB |
| Contracts | 40 / 16,048 | 0,512 | 0,647 | 14,889 | 11 + 11; 1,149 MiB |
| Deck Mutations | 187 / 16,808 | 0,476 | 1,234 | 15,097 | 84 + 84; 1,709 MiB |
| Events | 36 / 1,299 | 0,401 | 0,898 | 0,000 | 18 + 18; 1,296 MiB |
| Gameplay Core | 4 / 0,198 | 0,046 | 0,152 | 0,000 | 2 + 2; 0,198 MiB |
| Horizons | 92 / 0,979 | 0,329 | 0,650 | 0,000 | 46 + 46; 0,979 MiB |
| Joker Fusion | 21 / 17,290 | 0,057 | 0,193 | 17,041 | 5 + 5; 0,249 MiB |
| RISK JOKERS | 24 / 9,545 | 0,091 | 0,296 | 9,157 | 9 + 9; 0,387 MiB |
| UPG JOKERS | 29 / 13,688 | 0,131 | 0,291 | 13,265 | 8 + 8; 0,422 MiB |
| **Paquetes** | **534 / 110,817** | **2,416** | **4,881** | **103,520** | **220 + 220; 7,280 MiB** |
| Black Market (arte conceptual, no es paquete) | 2 / 3,660 | — | — | 3,660 | No se empaqueta |
| **MODS total en disco** | **536 / 114,477** |  |  |  |  |

Resumen de otras carpetas gráficas (estas rutas no se suman entre sí cuando hay
una relación padre/hijo):

| Ruta | Contenido gráfico en disco | Uso |
| --- | ---: | --- |
| `balatron/src/resources/textures/` | 136 PNG, 3,723 MiB en disco; 3,483 MiB comprimidos en `Game.love` (1x: 1,630; 2x: 2,093) | Fuentes base empaquetadas; solo una escala principal se carga por sesión. |
| `balatron/src/assets/skins/` | 13 PNG, 16,880 MiB en disco; 16,781 MiB comprimidos en `Game.love` | Atlas finales de las seis skins listadas en `card_skins.lua`. |
| `balatron/assets/skins/` | 244 PNG, 145,306 MiB | Masters, exportaciones y fuentes; no se empaqueta porque el builder archiva `src/`. |
| `balatron/assets/` completo | 356 PNG, 240,295 MiB | Arte y fuentes de producción, excluidos del `.love` salvo sus salidas copiadas bajo `src/`. |
| `DECK1/` | 5 PNG, 10,037 MiB | Fuentes de Deck 1. |
| `DECK 2/` | 65 PNG, 125,545 MiB | Diseños/fuentes, no registrados como skin runtime. |
| `DECK 3/` | 116 PNG, 172,405 MiB | Diseños/fuentes, no registrados como skin runtime. |
| `balatron/ios/` | 19 PNG, 3,469 MiB | Iconos/recursos del bundle iOS; no son atlas de juego. |
| `balatron/game_original_files/resources/textures/` | 136 PNG, 3.903.875 bytes | Extracción ignorada local, byte por byte idéntica a `src/resources/textures`; no va a GitHub ni a `Game.love`. Se conserva como dato de extracción local. |

La carpeta local `Balatro/` tiene el ejecutable y bibliotecas; las texturas se
extraen a `balatron/src/resources/`. No se distribuye ni se modifica el juego
original.

### Bundle existente y ahorro aplicado al builder

El `Game.love` local y el `Game.love` embebido en `balatron/balatron.ipa` son
idénticos, de 96.598.751 bytes. La inspección ZIP encontró estos archivos
añadidos por el builder bajo `install_mods/`:

| Ruta que se excluye | Archivos | Bytes fuente | Bytes comprimidos dentro de `Game.love` |
| --- | ---: | ---: | ---: |
| `contracts/art-source/expansion/` | 11 | 12.849.845 | 10.557.181 |
| `joker_fusion/art-source/` | 1 | 1.670.416 | 1.488.995 |
| **Total** | **12** | **14.520.261** | **12.046.176** |

Referencias examinadas: Contracts registra las imágenes runtime desde
`assets/{1x,2x}/expansion/<id>.png` (`MODS/Contracts/ui.lua`). El path de Joker
Fusion apunta a `assets/{1x,2x}/broken_copier.png`
(`MODS/Joker Fusion/copier.lua`). Los originales de alta resolución solo están
referenciados en manifests/prompts de arte, que el builder ya excluye. La
corrección en `balatron/build.py` filtra las dos carpetas `art-source` sin borrar
ningún archivo de fuente ni tocar los registros.

La simulación de reempaquetado en memoria, quitando solo esas doce entradas del
`Game.love` local, obtuvo:

| Medición | Antes | Proyección tras filtro | Diferencia |
| --- | ---: | ---: | ---: |
| Archivo interno `Game.love` | 96.598.751 B | 84.550.251 B | −12.048.500 B / −11,490 MiB |
| Entrada deflate de `Game.love` en una IPA | 96.299.628 B | 84.248.534 B | −12.051.094 B / −11,493 MiB |

Esto cuantifica el ahorro del cambio de empaquetado sobre la build existente;
no representa una IPA regenerada. La IPA actual sigue teniendo los doce recursos.

## Formatos, atlas, referencias y duplicados

- En `MODS/` hay 529 PNG y 7 JPEG. Todos los assets runtime examinados bajo
  `assets/1x` y `assets/2x` son PNG en modo RGB o RGBA; las imágenes JPEG quedan
  en arte de fuente/concepto y no son atlas runtime.
- Cada mod aporta parejas completas 1x/2x (220 PNG por escala en total) y todos
  los pares comprobados duplican ancho/alto exactamente. El builder incluye
  ambas escalas porque la opción de textura puede alternar entre 1 y 2.
- No hay directorios 4x en `MODS/` ni en las texturas base. El 4x se usa solo en
  Deck 1 mediante `dpi=4` en `CardSkins.registry`.
- Las 68 parejas de PNG base también cuadran en nombres y dimensiones. El alias
  Tarot/Planet/Spectral evita cargar copias para esas dos categorías.
- Se encontraron doce claves Atlas literales únicas en el scan simple. Muchas
  declaraciones son dinámicas; un chequeo ingenuo del nombre de archivo da 66
  rutas candidatas sin una mención literal (por ejemplo estados A/B y
  `run_rules/<id>`). Eso no confirma sprites huérfanos: sus rutas se forman en
  loops/registros. No se eliminó ningún asset.
- Único grupo idéntico byte a byte encontrado dentro de `MODS/`:
  `Compound Interest/arte_original.png` y
  `Compound Interest/Imagen de ChatGPT 6 oct 2026, 14_38_43.png` (1.363.505 B
  cada uno). Son imágenes fuente en la raíz del paquete y el builder no las
  copia; se conservan para no perder procedencia.
- No se encontraron otras duplicaciones binarias exactas en imágenes MODS. Los
  PNG 1x/2x no cuentan como duplicados: representan tamaños distintos.

## Memoria de texturas estimada

Estimación = ancho × alto × 4 bytes (RGBA8), y cadena mip completa aproximada
`× 4/3`. La GPU/driver puede usar otro formato, padding o asignación; la opción
de textura 2x es la base de cálculo del estado actual. La columna sin mip es el
suelo de textura RGBA, no RAM total del proceso.

| Grupo residente si se inyecta todo | Cuenta / píxeles | Sin mipmaps | Con cadena mip aprox. |
| --- | ---: | ---: | ---: |
| Atlas base: 65 a 2x + 2 logos a 1x | 22.905.041 px | 87,376 MiB | 116,501 MiB |
| Atlas MODS 2x | 220 PNG / 6.497.432 px | 24,786 MiB | 33,048 MiB |
| Deck 1: fronts/enhanced/back/wild | 4 texturas finales; enhanced se usa dos veces | 64,634 MiB | 86,179 MiB |
| Skins parciales | 10 PNG / 14.029.600 px | 53,519 MiB | 53,519 MiB (mipmaps desactivados) |
| **Total estimado** | — | **230,314 MiB** | **289,246 MiB** |

Con la escala base 1x, los atlas base representarían 29,816 MiB sin mipmaps y
39,754 MiB con mipmaps; los mods también seleccionan su pareja 1x. Los atlas
custom de cartas sumarían unos 139,697 MiB con el mipmap de Deck 1. El
código carga los atlas de las cinco skins parciales y Deck 1 al inicializar
render, aunque el ajuste guardado sea Default. Por eso el ahorro más grande de
memoria potencial está en carga diferida/liberación de skins no activas, no en
reducir la resolución de cada sprite. No se implementó porque implica validar
colecciones, previews, alternancia de skin, cambios de escala/render y retención
de referencias Sprite en runtime.

La inyección SMODS además conserva `ImageData` junto a `Image` en el objeto Atlas.
Las 220 texturas 2x de mods equivalen a unas 24,786 MiB extra de píxeles RGBA en
RAM CPU si esos objetos mantienen sus buffers. Liberarlos podría ahorrar RAM,
pero puede romper mods que consulten la API del Atlas; requiere investigación y
prueba de compatibilidad separada.

## Optimizaciones y estado

### Aplicada

- Excluir `MODS/Contracts/art-source/` y
  `MODS/Joker Fusion/art-source/` dentro de `_bundled_mods()`. Los originales se
  mantienen en disco. No cambia pixels, atlas, localización, registros, gameplay
  o guardados. Ahorro próximo `.love`/IPA estimado: 11,490/11,493 MiB según la
  simulación ZIP anterior.

### No aplicada

- Se probó en memoria una re-compresión PNG de los 589 PNG empaquetables
  inventariados (base 1x/2x, mods 1x/2x y CardSkins; el conjunto también incluye
  variantes base no cargadas como `balatro_alt.png` y logos 2x). 542 producirían archivos menores y todos los
  candidatos comprobados conservaron exactamente modo, dimensiones, bytes de
  pixel/alpha y metadatos de color; la suma bruta sería 717.210 B y la reducción
  comprimida de `Game.love` unos 677.810 B (0,646 MiB). No se cambiaron esos 542
  archivos: el beneficio empaquetado es menor de 0,7 MiB frente a un diff
  binario masivo que conserva duplicados de blobs en el historial Git. Se puede
  reconsiderar con un flujo PNG lossless reproducible y decisión de repositorio.
- No se quitó `balatro_alt.png`: el escaneo textual local no encontró una
  referencia en el juego ni en los mods incluidos, pero puede ser consumido por
  mods externos. Tampoco se quitó el par fuente idéntico de Compound Interest ni la extracción
  ignorada `game_original_files/`; no afectan al bundle y se mantienen por
  procedencia/reversibilidad. La extracción de texturas tiene una copia exacta
  de 3.903.875 B junto a `src/resources/`; limpiar ese directorio es una tarea de
  housekeeping local, no parte de este cambio.
- No se rebajó 4x de Deck 1, no se borraron escalas 1x/2x, no se fusionaron ni
  recortaron atlas, no se cambió `disable_mipmap` y no se alteraron PNG
  runtime. Cada una de esas opciones puede degradar nitidez, disponibilidad de
  escala o compatibilidad de Sprite.

## Comprobaciones realizadas y pendientes

Realizadas: Pillow pudo abrir todas las imágenes auditadas; formatos y
dimensiones inventariados; pares base y mod 1x/2x comprobados; claves literales y
referencias de atlas revisadas; builder ejecutado solo como función de lectura
`_bundled_mods()` sin escribir artefactos; hashes de imágenes MODS comparados con
las entradas existentes de `Game.love` (0 diferencias/0 ausencias antes del
filtro); las doce rutas de concepto fueron listadas dentro del `.love`; Python
AST de `build.py`, `git diff --check` y paths del informe se comprueban al cerrar.

Pendiente: no se midió el renderer real ni memoria GPU en iPhone, no se probó una
partida con el filtrado nuevo, no se verificó cada ruta generada dinámicamente
contra un runtime atlas trace, ni se generó una nueva IPA. La IPA existente
conserva las imágenes que el builder dejará fuera en una build futura.
