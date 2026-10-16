# Balatrón — build personal para iPhone

**Release actual: 2.8.1 / ios-portrait-rc2-ui.** Incluye packs portrait compartidos
con Steamodded, SHOP en cabecera, doce iconos de mutaciones y Deck 1 con mayor
contraste por palo. Deck 2 y Deck 3 siguen guardados como trabajo pendiente.
Incluye los módulos locales, arte
aprobado y QoL acumulados. Comprobada con LÖVE/Lovely/Steamodded en escritorio;
la instalación, safe areas y respuesta háptica reales requieren iPhone.


**Entrega `ios-portrait-7-ios-mod-path`:** corrige el fallo de arranque observado
en iPhone por el alias `/private/var` ↔ `/var` y barras finales. El instalador
compara rutas normalizadas, conserva la detección de destinos distintos y verifica
la lectura de ambos mods desde la ruta absoluta de Lovely. Usa el container actual,
sin UUID fijo. No modifica gameplay, gráficos, controles ni guardado del perfil.

**Entrega `ios-portrait-6-background-cycle`:** nueva ilustración de Compound Interest
(bufón con monedas y flecha ascendente), sprites 1x/2x y mod 1.0.2. Fondo original
con ciclo suave de siete colores de 240 segundos. Las ondas originales siguen
moviéndose. Options → Settings → Graphics → Animated Background / Fondo animado
permite fijar el verde sin detener las ondas; la elección se guarda.
Paleta y duración: `src/portrait_config.lua`; aplicación: `src/portrait_background.lua`.
No se han sustituido imágenes ni shaders del fondo. Ver `INFORME-PRUEBAS.md`.

**Entrega `ios-portrait-5-compound-collection`:** Interés compuesto aparece en
Collection → Jokers desde el inicio, desbloqueado pero no descubierto. La primera
adquisición en partida normal registra el descubrimiento permanente del perfil.
Conserva la probabilidad del 1 % y los descubrimientos ya guardados.

**Entrega anterior `ios-portrait-4-compound-interest`:** añade Interés compuesto, con
Steamodded fijado e instalado automáticamente antes de cargar el juego. Precio
$10, X1 inicial, +0,15 por ciega ganada y 1 % por oferta normal elegible de Joker.
Conserva los cambios anteriores y migra partidas existentes guardando una copia
`<perfil>/save.pre-steamodded.jkr`. Mod y configuración en `../MODS/Compound Interest`.
Detalles de integración: `mods/README.md`; pruebas: `INFORME-PRUEBAS.md`.

**Entrega anterior `ios-portrait-3-deck1`:** añade Deck 1, seleccionable desde
Options → Customize Deck → Card Skin. Conserva Default, la redistribución portrait,
las mejoras de nitidez y textos, los comodines adaptativos y el icono del bufón.
La skin usa las fotos finales actualizadas y el 8 de tréboles corregido con autorización.
Ver `INFORME-PRUEBAS.md` para los resultados y hashes de esta entrega.

Salida: `balatron.ipa`, preparada para volver a firmar con AltStore o
Sideloadly. Nombre: **Balatrón**. ID: `com.rulo3.balatro.portrait`.
No sustituye deliberadamente Balatro oficial. La instalación y el comportamiento
real en iPhone quedan pendientes de prueba física; ver `INFORME-PRUEBAS.md`.

## Recompilar

Desde PowerShell, dentro de este directorio:

```powershell
.\BUILD-IOS.ps1
# Otra instalación o Python:
.\BUILD-IOS.ps1 -GameSource 'D:\Steam\steamapps\common\Balatro\Balatro.exe' -PythonPath 'C:\Python312\python.exe'
```

Comando equivalente con Python disponible en PATH:

```text
python build.py --ios --skip-apk --keep-crt --no-readabletro --force --balatro "../Balatro/Balatro.exe"
python tools/validate_ipa.py
```

`--ios` sigue siendo válido; `--skip-apk` evita construir también Android.
Esta build usa Balatro **1.0.1o-FULL**, conserva sus gráficos y audio locales y
incluye Steamodded fijado. Conserva `balatro-mobile-maker/lovely-base.ipa`: está
verificado por SHA-256 y permite recompilar sin depender de que el proveedor
mantenga la misma descarga. Si cambias la versión del juego, utiliza una copia
nueva del proyecto y revisa los parches: el código portrait está basado en 1.0.1o.

## Ajustes y diagnóstico

Deck 1 incluye las 52 caras y el reverso. Su elección persiste al cerrar y abrir.
Registro: `src/card_skins.lua`; fuentes, manifiesto y guía para Deck 2:
`assets/skins/deck1/README.md`. Los atlas originales se conservan.

El icono está integrado en el bundle iOS con 18 variantes RGB sin transparencia.
Máster: `ios/icon-master.png`; catálogo: `ios/Assets.xcassets/AppIcon.appiconset`.
`tools/generate_ios_icons.py` regenera los tamaños y `tools/ios_icons.py`
conecta sus referencias durante el empaquetado. Detalles en `ios/README.md`.

`src/portrait_config.lua` centraliza escalas, cartas, HUD, márgenes, umbral de
arrastre, swipes y tamaño táctil. Mantiene Jugar/Descartar visibles por defecto.
La nueva composición se ajusta en `layout`, la nitidez en `quality` y los textos
del HUD en `mobile_ui`. `hud_top_space`, `jokers_y`, `deck_position` y `card_scale`
son claves antiguas conservadas por compatibilidad; no controlan el nuevo layout.
Para usar gestos, selecciona cartas y desliza una carta ya seleccionada hacia
arriba para jugar o hacia abajo para descartar. Los gestos pueden desactivarse
con `gestures.enabled = false` (manteniendo desactivado Swipe Only).

Options → Diagnostics muestra un informe paginado. Copy to clipboard copia el
informe completo y escribe `portrait-diagnostics.txt` en el directorio del juego.
Los valores UIKit solo existen en iOS; `?` indica que no pudo consultarlos.

## Guardado y mods

Conserva el mismo ID de aplicación y la misma identidad de firma al actualizar.
No desinstales la aplicación para actualizarla. Copia `game/` desde Archivos
antes de una actualización importante. El sandbox nuevo no importa automáticamente
las partidas de la app oficial ni de builds con otro ID.

Lovely y Steamodded fijados están integrados. La ruta móvil esperada es
Archivos → En mi iPhone → Balatrón → `game/Mods/`. El instalador despliega y verifica los mods incluidos antes del arranque.
La validación física en iPhone sigue pendiente.

## Procedencia

Base 2.8.0, commit `27bf84cdde604fe1917f5c41a5488f385ea1463d` del 15/09/2026,
recuperado del historial de `beiklive/balatro-portrait-mobile`. El repositorio
solicitado `ShaggyLorean/balatro-portrait-mobile` devolvía 404 durante el trabajo.
Se excluyó el commit posterior del fork y el paquete gráfico Readabletro.
Rama de trabajo: `ios-portrait-production`. No se ha publicado ni subido la IPA.
