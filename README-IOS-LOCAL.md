# Balatro Portrait — build personal para iPhone

Salida: `balatro-portrait.ipa`, preparada para volver a firmar con AltStore o
Sideloadly. Nombre: **Balatro Portrait**. ID: `com.rulo3.balatro.portrait`.
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
no instala Steamodded. Conserva `balatro-mobile-maker/lovely-base.ipa`: está
verificado por SHA-256 y permite recompilar sin depender de que el proveedor
mantenga la misma descarga. Si cambias la versión del juego, utiliza una copia
nueva del proyecto y revisa los parches: el código portrait está basado en 1.0.1o.

## Ajustes y diagnóstico

`src/portrait_config.lua` centraliza escalas, cartas, HUD, márgenes, umbral de
arrastre, swipes y tamaño táctil. Mantiene Jugar/Descartar visibles por defecto.
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

Lovely está integrado; Steamodded es opcional. La ruta móvil esperada es
Archivos → En mi iPhone → Balatro Portrait → `game/Mods/`. No se han instalado
mods en esta entrega ni se ha verificado su carga en un iPhone.

## Procedencia

Base 2.8.0, commit `27bf84cdde604fe1917f5c41a5488f385ea1463d` del 15/09/2026,
recuperado del historial de `beiklive/balatro-portrait-mobile`. El repositorio
solicitado `ShaggyLorean/balatro-portrait-mobile` devolvía 404 durante el trabajo.
Se excluyó el commit posterior del fork y el paquete gráfico Readabletro.
Rama de trabajo: `ios-portrait-production`. No se ha publicado ni subido la IPA.
