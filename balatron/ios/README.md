# Icono de Balatrón

`icon-master.png` es el máster cuadrado de 1024 × 1024 píxeles, RGB opaco.
Procede de la imagen aportada por el usuario, «Bufón caótico con cartas y
fichas.png». Se han extendido sus esquinas al cuadrado completo con imagegen
(modo edición), conservando la composición, el personaje y las cartas, sin
añadir texto. iOS aplica la máscara de esquinas del sistema.

`Assets.xcassets/AppIcon.appiconset/Contents.json` define 18 variantes:

| Uso | Puntos | Escalas |
| --- | --- | --- |
| iPhone: notificaciones, ajustes, búsqueda e inicio/biblioteca | 20, 29, 40, 60 | 2x, 3x |
| iPad: notificaciones, ajustes y búsqueda | 20, 29, 40 | 1x, 2x |
| iPad: inicio/biblioteca | 76 | 1x, 2x |
| iPad Pro: inicio/biblioteca | 83,5 | 2x |
| Marketing | 1024 | 1x |

Regeneración: `python tools/generate_ios_icons.py` (requiere Pillow).
Usa reducción Lanczos y guarda PNG RGB sin transparencia. Las builds normales
consumen los PNG ya generados y no necesitan Pillow.

El proyecto empaqueta un motor iOS precompilado. `build.py` copia los PNG a la
raíz del bundle, retira los iconos anteriores y reemplaza `CFBundleIcons`,
`CFBundleIcons~ipad` y `CFBundleIconFiles` en `Info.plist`. No conserva
`CFBundleIconName`, porque esta ruta utiliza imágenes del bundle, no un
`Assets.car` compilado. El catálogo también queda preparado como fuente para
Xcode. Los nombres 1x no llevan sufijo de densidad, y los de iPad llevan `~ipad`.

El nombre visible, el identificador de la aplicación y el ejecutable nativo
permanecen iguales. No se habilitan notificaciones: se incluye su tamaño de icono
para los usos estándar del sistema.

Referencias de Apple:
[tamaños y configuración](https://developer.apple.com/library/archive/qa/qa1686/)
y [CFBundleIconFiles](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleicons/cfbundleprimaryicon/cfbundleiconfiles).

Instrucción de edición del máster:

> Edit this provided image for an iOS app icon master. Preserve the existing grotesque funny red-and-blue jester face, eyes, teeth, tongue, playing cards, gold bells, lighting, materials, colours and overall composition as closely as possible. This is a minimal production adaptation of the supplied artwork, not a new character design. Output a square, opaque, full-bleed image. Remove the baked-in rounded-square outline/black outside corners by extending the existing dark red/blue background naturally to all four square corners. Do not add an icon border or rounded corners; iOS will mask it. Keep the expressive face as the focal point, with slightly comfortable edge clearance for important facial features. Do not add any text, lettering, logos or additional objects. Keep the overall image extremely close to the supplied image, especially the face.
