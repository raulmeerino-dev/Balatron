# Deck 1 — integración

Seleccionar **Options → Customize Deck → Card Skin → Deck 1**. El cambio es
inmediato, se aplica también a cartas ya creadas y se guarda en `settings.jkr`.
**Default** conserva la baraja original y las colaboraciones por palo guardadas.
El menú existente contiene el selector; no hay un segundo sistema de ajustes.

## Fuente y procesado

Se utilizan exclusivamente las cinco láminas finales de `../DECK1` actualizadas
por el usuario el 6 de octubre de 2026. `manifest.json` registra sus nombres,
SHA-256, recortes y la posición de cada rango/palo en el atlas. Los originales
no se modifican. Hay 52 caras y un reverso, sin Joker de baraja adicional.

`tools/build_card_skin.py` detecta el borde crema sobre el fondo oscuro mediante
proyecciones de filas/columnas. Exige 13 rectángulos en cada lámina y uno en el
reverso; rechaza cantidades y proporciones inesperadas. Conserva el contenido
interior, incluso el negro de las ilustraciones, y elimina únicamente el fondo
exterior. Normaliza el lienzo con márgenes crema y silueta redondeada común.
El escalado conserva la proporción; no estira las ilustraciones ni recorta índices.

- Fuentes editables: `assets/skins/deck1/cards/`, 53 PNG RGBA de **284 × 380**.
- Caras en ejecución: `src/assets/skins/deck1/fronts.png`, **3692 × 1520**.
- Capa para cartas mejoradas: `src/assets/skins/deck1/enhanced.png`, misma medida.
- Reverso: `src/assets/skins/deck1/back.png`, **284 × 380**.
- Celda del motor: **71 × 95 unidades**, densidad **4x**, sin cambiar hitboxes.
- Columnas: 2–10, J, Q, K, A. Filas: Hearts, Clubs, Diamonds, Spades, igual que
  `G.P_CARDS`. Filtrado lineal y mipmaps; margen transparente dentro de la celda.

La fuente todavía tenía seis tréboles centrales en el 8. La corrección de ocho
fue autorizada por el usuario y realizada con imagegen en modo edición,
conservando los índices, el palo y el diseño. Se guarda en `corrections/clubs_8.png`
y el generador la incorpora de forma reproducible. Las otras 51 caras se
extraen de las láminas sin rediseñarlas. `contact-sheet.png` permite revisar todas.

## Integración con Balatro

`src/card_skins.lua` centraliza registro, carga, elección y actualización. Se
engancha en la carga de atlas de `game.lua`, `get_front_spriteinfo` y
`Card:set_sprites`. El dorso nuevo se aplica solo a objetos de playing cards,
incluidas las vistas previas. La selección mecánica Red/Blue/etc. y sus efectos
se conservan; la colección de esos mazos mantiene sus diseños identificativos.

La capa `enhanced` elimina el papel crema para dejar visible el fondo original
de oro, acero, cristal, bonus, etc. Piedra conserva su representación original.
Ediciones, sellos, debuffs y animaciones siguen pasando por los shaders existentes.
Los atlas originales de Jokers, consumibles, Tarot, Planet, Spectral, vouchers y
boosters permanecen intactos. No se modifica la lógica de rangos, palos o puntuación.

Deck 1 conserva la paleta de las láminas. Las colaboraciones y la paleta alternativa
de alto contraste originales se editan con **Default**; sus preferencias se
conservan al pasar a Deck 1 y volver. No se inventa una segunda paleta del artista.

## Regenerar y añadir Deck 2

Requiere Python, Pillow y numpy:

```text
python tools/build_card_skin.py --source "../DECK1" --skin deck1
python -m unittest discover -s tests -p "test_*.py"
python tools/lua_check.py --run tests/card_skins_test.lua
```

Para otra baraja con láminas del mismo tipo, crear DECK2 con CORAZON, PICAS,
TREBOL, ROMBOS y REVERSO; ejecutar el generador con `--source "../DECK2" --skin deck2`.
Añadir `deck2` a `CardSkins.order` y registrar
`deck2 = {label='Deck 2', path='assets/skins/deck2/', dpi=4}` en `CardSkins.registry`.
El selector, la carga y la persistencia utilizan ese registro automáticamente.
Revisar la hoja de contacto y recompilar con `BUILD-IOS.ps1`.

Las pruebas validan nombres, cantidad, dimensiones, formato, alpha, duplicados,
correspondencia exacta de cada celda, procedencia de las fotos actuales y el
reverso. Las capturas usan LÖVE de escritorio con coordenadas y DPI simulados de
iOS; no sustituyen una instalación física en iPhone.
